import Foundation

@Observable
final class HistoryManager {
    private(set) var records: [TranscriptionRecord] = []

    init() { load() }

    func add(_ text: String) {
        let record = TranscriptionRecord(id: UUID(), text: text, date: Date())
        records.insert(record, at: 0)
        if records.count > 50 { records = Array(records.prefix(50)) }
        save()
    }

    func remove(_ id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        records.removeAll()
        save()
    }

    var wordsToday: Int {
        records.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.wordCount }
    }

    var wordsThisWeek: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return records.filter { $0.date >= start }
            .reduce(0) { $0 + $1.wordCount }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "transcriptionHistory")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "transcriptionHistory"),
              let decoded = try? JSONDecoder().decode([TranscriptionRecord].self, from: data)
        else { return }
        records = decoded
    }
}
