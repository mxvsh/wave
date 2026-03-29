import SwiftUI

struct SnippetsPageView: View {
    @Environment(AppState.self) private var appState
    @State private var editingSnippet: Snippet? = nil
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.snippetManager.snippets.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 24))
                        .foregroundStyle(.quaternary)
                    Text("No snippets yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.snippetManager.snippets) { snippet in
                            SnippetRow(snippet: snippet) {
                                editingSnippet = snippet
                            } onDelete: {
                                appState.snippetManager.remove(snippet.id)
                            }
                        }
                    }
                }

                Text("Right-click a snippet for more options")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            SnippetSheet(snippet: nil) { name, value in
                appState.snippetManager.add(name: name, value: value)
            }
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetSheet(snippet: snippet) { name, value in
                appState.snippetManager.update(id: snippet.id, name: name, value: value)
            }
        }
    }
}

// MARK: - Snippet Row

private struct SnippetRow: View {
    let snippet: Snippet
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(snippet.value)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(snippet.value, forType: .string)
            }
            Button("Edit") { onEdit() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Add / Edit Sheet

private struct SnippetSheet: View {
    let snippet: Snippet?
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""

    var isEditing: Bool { snippet != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Snippet" : "New Snippet")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Snippet")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                TextField("Github Profile", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Value")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                TextEditor(text: $value)
                    .font(.system(size: 13))
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Button(isEditing ? "Update" : "Save") {
                    onSave(name, value)
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.brand.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                .foregroundStyle(Color.brand)
                .buttonStyle(.plain)
                .disabled(name.isEmpty || value.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear {
            if let snippet {
                name = snippet.name
                value = snippet.value
            }
        }
    }
}
