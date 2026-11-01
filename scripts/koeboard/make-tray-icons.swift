// Koeboard のトレイ（メニューバー）アイコンを作る。
// 使い方: swift scripts/koeboard/make-tray-icons.swift src-tauri/resources
// 波形の入ったキーを、テーマごとの色で 64x64 に描く。
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")

enum Glyph { case idle, recording, transcribing, warning }

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}

func bars(in key: NSRect, heights: [CGFloat], width: CGFloat, gap: CGFloat) -> [NSBezierPath] {
    let maxHeight = key.height * 0.62
    let total = CGFloat(heights.count) * width + CGFloat(heights.count - 1) * gap
    var x = key.midX - total / 2
    return heights.map { h in
        let height = max(width, maxHeight * h)
        let r = NSRect(x: x, y: key.midY - height / 2, width: width, height: height)
        x += width + gap
        return NSBezierPath(roundedRect: r, xRadius: width / 2, yRadius: width / 2)
    }
}

/// - ink: 線の色。filled: キーを塗りつぶす色（録音中）
func draw(_ glyph: Glyph, ink: NSColor, fill: NSColor? = nil, name: String) {
    let px = 64
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let key = NSRect(x: 4, y: 12, width: 56, height: 42)
    let path = NSBezierPath(roundedRect: key, xRadius: 11, yRadius: 11)
    path.lineWidth = 5
    let heights: [CGFloat] = [0.35, 0.7, 1, 0.6, 0.35]
    switch glyph {
    case .recording:
        (fill ?? ink).setFill(); path.fill()
        NSColor.white.setFill()
        bars(in: key, heights: [0.35, 0.75, 1, 0.6, 0.35], width: 4.5, gap: 4).forEach { $0.fill() }
    case .transcribing:
        ink.setStroke(); path.stroke()
        ink.setFill()
        for i in -1...1 {
            let d: CGFloat = 7.5
            NSBezierPath(ovalIn: NSRect(x: key.midX + CGFloat(i) * 12 - d / 2, y: key.midY - d / 2, width: d, height: d)).fill()
        }
    case .idle, .warning:
        ink.setStroke(); path.stroke()
        ink.setFill()
        bars(in: key, heights: heights, width: 4.5, gap: 4).forEach { $0.fill() }
        if glyph == .warning {
            let dot = NSRect(x: 46, y: 42, width: 17, height: 17)
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: dot.insetBy(dx: -4, dy: -4)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            color(0xF5A524).setFill()
            NSBezierPath(ovalIn: dot).fill()
        }
    }
    NSGraphicsContext.current = nil
    try! rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent(name))
}

let white = NSColor.white, black = NSColor.black
let red = color(0xFF3B30), coral = color(0xFF5A6E), indigo = color(0x3A3392)

// ダークテーマ（白い線）とライトテーマ（黒い線、名前が _dark）
draw(.idle, ink: white, name: "tray_idle.png")
draw(.idle, ink: black, name: "tray_idle_dark.png")
draw(.recording, ink: white, fill: red, name: "tray_recording.png")
draw(.recording, ink: black, fill: red, name: "tray_recording_dark.png")
draw(.transcribing, ink: white, name: "tray_transcribing.png")
draw(.transcribing, ink: black, name: "tray_transcribing_dark.png")
draw(.warning, ink: white, name: "tray_idle_warning.png")
draw(.warning, ink: black, name: "tray_idle_warning_dark.png")
// 色付きテーマ
draw(.idle, ink: indigo, name: "handy.png")
draw(.recording, ink: coral, fill: coral, name: "recording.png")
draw(.transcribing, ink: indigo, name: "transcribing.png")
draw(.warning, ink: indigo, name: "handy_warning.png")
print("トレイのアイコンを作りました: \(outDir.path)")
