// アプリのアイコンを描く。使い方: swift scripts/make-icon.swift Resources/AppIcon-1024.png
// 「声（波形）」が刻まれた「キーボードのキー」。土台は macOS のアイコンの形（角の丸い正方形）。
import AppKit

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func withShadow(_ c: NSColor, blur: CGFloat, y: CGFloat, _ draw: () -> Void) {
    ctx.saveGState()
    let sh = NSShadow()
    sh.shadowColor = c
    sh.shadowBlurRadius = blur
    sh.shadowOffset = NSSize(width: 0, height: y)
    sh.set()
    draw()
    ctx.restoreGState()
}

// 土台：1024 の中に 824 の角丸（Apple のアイコンの決まり）
let base = NSRect(x: 100, y: 100, width: 824, height: 824)
let basePath = NSBezierPath(roundedRect: base, xRadius: 185, yRadius: 185)
withShadow(color(0x000000, 0.30), blur: 28, y: -12) { color(0x1A1840).setFill(); basePath.fill() }
ctx.saveGState()
basePath.addClip()
NSGradient(colors: [color(0x3A3392), color(0x221F5C), color(0x15133A)])!.draw(in: basePath, angle: -70)
// 上からの柔らかい光
NSGradient(colors: [color(0xFFFFFF, 0.16), color(0xFFFFFF, 0)])!
    .draw(fromCenter: NSPoint(x: 512, y: 980), radius: 0, toCenter: NSPoint(x: 512, y: 980), radius: 620, options: [])
ctx.restoreGState()

// キー：下のふち（スカート）と、少し小さい上面
let skirt = NSRect(x: 214, y: 232, width: 596, height: 560)
let skirtPath = NSBezierPath(roundedRect: skirt, xRadius: 120, yRadius: 120)
withShadow(color(0x000000, 0.45), blur: 40, y: -26) { color(0xC7CBE0).setFill(); skirtPath.fill() }
NSGradient(colors: [color(0xE9EBF5), color(0xB9BED6)])!.draw(in: skirtPath, angle: -90)

let top = NSRect(x: 252, y: 300, width: 520, height: 470)
let topPath = NSBezierPath(roundedRect: top, xRadius: 96, yRadius: 96)
withShadow(color(0x000000, 0.18), blur: 10, y: -4) { color(0xFFFFFF).setFill(); topPath.fill() }
NSGradient(colors: [color(0xFFFFFF), color(0xF1F2F8)])!.draw(in: topPath, angle: -90)
// 上面のふちの光
ctx.saveGState()
topPath.addClip()
NSGradient(colors: [color(0xFFFFFF, 0.9), color(0xFFFFFF, 0)])!.draw(in: NSRect(x: top.minX, y: top.maxY - 40, width: top.width, height: 40), angle: -90)
ctx.restoreGState()

// 波形（声）。キーの上面に刻まれたように少しくぼませる
let heights: [CGFloat] = [0.30, 0.58, 0.86, 1.0, 0.72, 0.46, 0.26]
let barWidth: CGFloat = 40
let gap: CGFloat = 22
let maxHeight: CGFloat = 300
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
var x = top.midX - totalWidth / 2
let barGradient = NSGradient(colors: [color(0xFF9A5C), color(0xFF5A6E), color(0xF0457F)])!
for h in heights {
    let height = maxHeight * h
    let bar = NSRect(x: x, y: top.midY - height / 2, width: barWidth, height: height)
    let path = NSBezierPath(roundedRect: bar, xRadius: barWidth / 2, yRadius: barWidth / 2)
    withShadow(color(0xFFFFFF, 0.9), blur: 0, y: -3) { color(0xF0457F).setFill(); path.fill() }
    barGradient.draw(in: path, angle: -90)
    x += barWidth + gap
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("作りました: \(out)")
