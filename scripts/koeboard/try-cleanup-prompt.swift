// Try Koeboard's cleanup prompt on Apple Intelligence, the way the app sends
// it (system prompt = template without ${output}, user = transcript).
// Usage: swift scripts/koeboard/try-cleanup-prompt.swift  (macOS 26+, Apple silicon)
import Foundation
import FoundationModels

// The app asks for a @Generable struct first; macros need full Xcode, so this
// uses the plain-text fallback the app also has.

let settings = try String(contentsOfFile: "src-tauri/src/settings.rs", encoding: .utf8)
guard let start = settings.range(of: "prompt: \"<transcript>\\n${output}"),
      let end = settings.range(of: "整えた文章だけを返す。\"", range: start.upperBound..<settings.endIndex)
else { fatalError("cleanup prompt not found in settings.rs") }
var template = String(settings[start.lowerBound..<end.upperBound])
template = String(template.dropFirst("prompt: \"".count).dropLast())
template = template.replacingOccurrences(of: "\\n", with: "\n")
let system = template.replacingOccurrences(of: "${output}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

let samples = CommandLine.arguments.count > 1 ? Array(CommandLine.arguments.dropFirst()) : [
    "えーと明日の会議は10時からじゃなくて11時からに変更になりましたよろしくお願いします",
    "資料は田中さんに、いや佐藤さんに送ってください",
    "あのーこれってどうやって設定するんですかね",
    "3個、じゃなくて4個注文しておいてください。あ、やっぱり5個で",
    "今日はですね、今日は天気がいいので、えー散歩に行こうと思います",
    "Let's meet on Monday, no wait, Tuesday at 3",
]

let model = SystemLanguageModel.default
guard model.availability == .available else { fatalError("Apple Intelligence unavailable: \(model.availability)") }
for text in samples {
    let session = LanguageModelSession(model: model, instructions: system)
    let started = Date()
    let out: String
    do {
        out = try await session.respond(to: text).content
    } catch {
        out = "(error: \(error))"
    }
    print(String(format: "%.1fs", Date().timeIntervalSince(started)), text, "\n   →", out)
}
