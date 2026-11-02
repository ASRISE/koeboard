//! Koeboard: the text before the cursor in the field being dictated into,
//! read through the OS accessibility API when a recording starts. It goes to
//! the speech model as context (models with a context prompt) and to the AI
//! cleanup, so names and terms already on the page are spelled the same way.
//! It never leaves the machine except through a cloud AI the user chose.
//! Password fields are never read.

use std::sync::Mutex;
use std::time::Duration;

use log::debug;

/// At most this many characters before the cursor.
const MAX_CHARS: usize = 200;
/// Reading can block on an unresponsive app; give up after this.
const TIMEOUT: Duration = Duration::from_millis(400);

static CURRENT: Mutex<Option<String>> = Mutex::new(None);

/// Read the context for a recording that is starting, in the background so
/// the recording isn't delayed. Clears the previous recording's context.
pub fn capture() {
    *CURRENT.lock().unwrap_or_else(|e| e.into_inner()) = None;
    std::thread::spawn(|| {
        let (tx, rx) = std::sync::mpsc::channel();
        std::thread::spawn(move || {
            let _ = tx.send(platform::text_before_cursor());
        });
        match rx.recv_timeout(TIMEOUT) {
            Ok(Some(text)) => {
                let text = tail(text.trim(), MAX_CHARS);
                if !text.is_empty() {
                    debug!("Cursor context: {} chars", text.chars().count());
                    *CURRENT.lock().unwrap_or_else(|e| e.into_inner()) = Some(text);
                }
            }
            Ok(None) => debug!("No cursor context"),
            Err(_) => debug!("Reading the cursor context timed out"),
        }
    });
}

/// Forget the context (the recording was transcribed or cancelled).
pub fn clear() {
    *CURRENT.lock().unwrap_or_else(|e| e.into_inner()) = None;
}

/// The current recording's context, if one was read.
pub fn current() -> Option<String> {
    CURRENT.lock().unwrap_or_else(|e| e.into_inner()).clone()
}

/// The last `max` characters of `text`.
fn tail(text: &str, max: usize) -> String {
    let count = text.chars().count();
    text.chars().skip(count.saturating_sub(max)).collect()
}

#[cfg(target_os = "macos")]
mod platform {
    use core_foundation::base::{CFGetTypeID, CFRelease, CFTypeRef, TCFType};
    use core_foundation::string::{CFString, CFStringGetTypeID, CFStringRef};
    use std::ffi::c_void;

    type AXUIElementRef = *const c_void;
    type AXError = i32;
    const AX_SUCCESS: AXError = 0;
    const AX_VALUE_CF_RANGE_TYPE: u32 = 4;

    #[repr(C)]
    #[derive(Default)]
    struct CFRange {
        location: isize,
        length: isize,
    }

    #[link(name = "ApplicationServices", kind = "framework")]
    extern "C" {
        fn AXIsProcessTrusted() -> bool;
        fn AXUIElementCreateSystemWide() -> AXUIElementRef;
        fn AXUIElementCopyAttributeValue(
            element: AXUIElementRef,
            attribute: CFStringRef,
            value: *mut CFTypeRef,
        ) -> AXError;
        fn AXUIElementGetTypeID() -> usize;
        fn AXValueGetTypeID() -> usize;
        fn AXValueGetValue(value: CFTypeRef, value_type: u32, out: *mut c_void) -> bool;
    }

    /// An owned CF object, released on drop.
    struct Owned(CFTypeRef);
    impl Drop for Owned {
        fn drop(&mut self) {
            if !self.0.is_null() {
                unsafe { CFRelease(self.0) };
            }
        }
    }

    fn attribute(element: CFTypeRef, name: &str) -> Option<Owned> {
        let name = CFString::new(name);
        let mut value: CFTypeRef = std::ptr::null();
        let err = unsafe {
            AXUIElementCopyAttributeValue(element, name.as_concrete_TypeRef(), &mut value)
        };
        (err == AX_SUCCESS && !value.is_null()).then(|| Owned(value))
    }

    fn string(value: &Owned) -> Option<String> {
        if unsafe { CFGetTypeID(value.0) } != unsafe { CFStringGetTypeID() } {
            return None;
        }
        let s = unsafe { CFString::wrap_under_get_rule(value.0 as CFStringRef) };
        Some(s.to_string())
    }

    pub fn text_before_cursor() -> Option<String> {
        if !unsafe { AXIsProcessTrusted() } {
            return None;
        }
        let system = Owned(unsafe { AXUIElementCreateSystemWide() });
        let focused = attribute(system.0, "AXFocusedUIElement")?;
        if unsafe { CFGetTypeID(focused.0) } != unsafe { AXUIElementGetTypeID() } {
            return None;
        }
        // Never read password fields.
        if let Some(subrole) = attribute(focused.0, "AXSubrole").and_then(|v| string(&v)) {
            if subrole == "AXSecureTextField" {
                return None;
            }
        }
        let value = string(&attribute(focused.0, "AXValue")?)?;
        let utf16: Vec<u16> = value.encode_utf16().collect();
        let mut cursor = utf16.len();
        if let Some(range) = attribute(focused.0, "AXSelectedTextRange") {
            if unsafe { CFGetTypeID(range.0) } == unsafe { AXValueGetTypeID() } {
                let mut r = CFRange::default();
                let ok = unsafe {
                    AXValueGetValue(
                        range.0,
                        AX_VALUE_CF_RANGE_TYPE,
                        &mut r as *mut CFRange as *mut c_void,
                    )
                };
                if ok && r.location >= 0 {
                    cursor = cursor.min(r.location as usize);
                }
            }
        }
        Some(String::from_utf16_lossy(&utf16[..cursor]))
    }
}

#[cfg(windows)]
mod platform {
    use windows::Win32::System::Com::{
        CoCreateInstance, CoInitializeEx, CLSCTX_INPROC_SERVER, COINIT_MULTITHREADED,
    };
    use windows::Win32::UI::Accessibility::{
        CUIAutomation, IUIAutomation, IUIAutomationTextPattern, TextPatternRangeEndpoint_End,
        TextPatternRangeEndpoint_Start, UIA_TextPatternId,
    };

    pub fn text_before_cursor() -> Option<String> {
        unsafe {
            // This thread is ours alone; the result doesn't matter (already
            // initialized is fine).
            let _ = CoInitializeEx(None, COINIT_MULTITHREADED);
            let automation: IUIAutomation =
                CoCreateInstance(&CUIAutomation, None, CLSCTX_INPROC_SERVER).ok()?;
            let focused = automation.GetFocusedElement().ok()?;
            // Never read password fields.
            if focused.CurrentIsPassword().ok()?.as_bool() {
                return None;
            }
            let pattern: IUIAutomationTextPattern =
                focused.GetCurrentPatternAs(UIA_TextPatternId).ok()?;
            let selection = pattern.GetSelection().ok()?;
            if selection.Length().ok()? < 1 {
                return None;
            }
            let caret = selection.GetElement(0).ok()?;
            let before = pattern.DocumentRange().ok()?;
            before
                .MoveEndpointByRange(
                    TextPatternRangeEndpoint_End,
                    &caret,
                    TextPatternRangeEndpoint_Start,
                )
                .ok()?;
            let text = before.GetText(-1).ok()?;
            Some(text.to_string())
        }
    }
}

#[cfg(not(any(target_os = "macos", windows)))]
mod platform {
    pub fn text_before_cursor() -> Option<String> {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::tail;

    #[test]
    fn tail_keeps_the_last_characters() {
        assert_eq!(tail("あいうえお", 3), "うえお");
        assert_eq!(tail("abc", 10), "abc");
    }
}
