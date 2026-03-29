import SwiftUI
import AppKit

struct HomePageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stats
            HStack(spacing: 10) {
                StatCard(value: appState.historyManager.wordsToday, label: "Today")
                StatCard(value: appState.historyManager.wordsThisWeek, label: "This week")
            }
            .padding(16)

            Divider()

            // Recent transcriptions
            if appState.historyManager.records.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 24))
                        .foregroundStyle(.quaternary)
                    Text("No transcriptions yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                HStack {
                    Text("Recent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.historyManager.records) { record in
                            TranscriptionRow(record: record) {
                                appState.historyManager.remove(record.id)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            Text("\(label) \u{00B7} words")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Transcription Row

private struct TranscriptionRow: View {
    let record: TranscriptionRecord
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.text)
                    .font(.system(size: 12))
                    .lineLimit(2)
                Text(record.date, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(record.text, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
