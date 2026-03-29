import SwiftUI
import Combine

@Observable
final class OverlayState {
    var status: AppStatus = .idle  // Defined in AppState.swift
}

struct OverlayView: View {
    var overlayState: OverlayState

    var body: some View {
        HStack(spacing: 10) {
            switch overlayState.status {
            case .recording:
                WaveAnimationView(speed: 1.0)
            case .transcribing:
                WaveAnimationView(speed: 0.4)
            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            case .idle:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
        .fixedSize(horizontal: true, vertical: true)
    }
}

private struct WaveAnimationView: View {
    var speed: Double

    private let barCount = 10
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
        .frame(height: 20)
        .onReceive(timer) { _ in
            phase += speed * 0.1
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let x = Double(index) / Double(barCount - 1)
        let w1 = sin(phase + x * .pi * 2.1)
        let w2 = sin(phase * 1.7 + x * .pi * 3.4) * 0.5
        let w3 = sin(phase * 2.3 + x * .pi * 1.1) * 0.3
        let combined = (w1 + w2 + w3) / 1.8
        let minH: CGFloat = 2
        let maxH: CGFloat = 14
        return minH + maxH * CGFloat((combined + 1.0) / 2.0)
    }
}
