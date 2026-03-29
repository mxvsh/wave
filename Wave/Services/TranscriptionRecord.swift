import Foundation

struct TranscriptionRecord: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date

    var wordCount: Int {
        text.split(whereSeparator: \.isWhitespace).count
    }
}
