import Foundation

struct Snippet: Identifiable, Codable {
    let id: UUID
    var name: String
    var value: String
}

@Observable
final class SnippetManager {
    private(set) var snippets: [Snippet] = []

    init() { load() }

    func add(name: String, value: String) {
        snippets.append(Snippet(id: UUID(), name: name, value: value))
        save()
    }

    func update(id: UUID, name: String, value: String) {
        guard let index = snippets.firstIndex(where: { $0.id == id }) else { return }
        snippets[index].name = name
        snippets[index].value = value
        save()
    }

    func remove(_ id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "snippets")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "snippets"),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data)
        else { return }
        snippets = decoded
    }
}
