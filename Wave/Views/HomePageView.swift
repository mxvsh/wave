import SwiftUI
import AppKit
import Combine

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
                        ForEach(appState.historyManager.records.prefix(10)) { record in
                            TranscriptionRow(record: record) {
                                appState.historyManager.remove(record.id)
                            }
                        }
                    }
                }

                Text("Right-click for more options")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
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
    @State private var timeLabel: String = ""
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.text)
                    .font(.system(size: 12))
                    .lineLimit(3)
                Text(timeLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .onAppear { timeLabel = relativeTime(record.date) }
                    .onReceive(timer) { _ in timeLabel = relativeTime(record.date) }
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.text, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

private func relativeTime(_ date: Date) -> String {
    let seconds = Int(-date.timeIntervalSinceNow)
    if seconds < 60 { return "just now" }
    if seconds < 3600 { return "\(seconds / 60)m ago" }
    if seconds < 86400 { return "\(seconds / 3600)h ago" }
    return "\(seconds / 86400)d ago"
}
