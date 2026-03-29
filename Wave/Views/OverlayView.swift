import SwiftUI
import Combine

@Observable
final class OverlayState {
    var status: AppStatus = .idle
}

struct OverlayView: View {
    var overlayState: OverlayState

    var body: some View {
        ZStack {
            // Fixed container — never changes size or shape
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)

            // Inner content swaps
            Group {
                switch overlayState.status {
                case .idle:
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.3))
                        .frame(width: 24, height: 4)
                case .recording:
                    WaveAnimationView(speed: 1.0)
                case .transcribing:
                    WaveAnimationView(speed: 0.4)
                case .error(let message):
                    Text(message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: overlayState.status.isIdle)
        }
        .frame(width: 54, height: 30)
        .environment(\.colorScheme, .dark)
        .background(.clear)
    }
}

// MARK: - Wave bars

private struct WaveAnimationView: View {
    var speed: Double

    private let barCount = 9
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    @State private var phase: Double = 0

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.42, green: 0.52, blue: 1.0),
                                Color(red: 0.62, green: 0.42, blue: 1.0)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 2.5, height: barHeight(for: i))
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in phase += speed * 0.1 }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let x = Double(index) / Double(barCount - 1)
        let w1 = sin(phase + x * .pi * 2.1)
        let w2 = sin(phase * 1.7 + x * .pi * 3.4) * 0.5
        let w3 = sin(phase * 2.3 + x * .pi * 1.1) * 0.3
        let combined = (w1 + w2 + w3) / 1.8
        return 2 + 12 * CGFloat((combined + 1.0) / 2.0)
    }
}

// MARK: - Helpers

extension AppStatus {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
}
