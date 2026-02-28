import SwiftUI

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
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .modifier(PulseModifier())
                Text("Listening...")
                    .font(.system(size: 14, weight: .medium))
            case .transcribing:
                ProgressView()
                    .scaleEffect(0.7)
                    .controlSize(.small)
                Text("Transcribing...")
                    .font(.system(size: 14, weight: .medium))
            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
            case .idle:
                EmptyView()
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
        .fixedSize(horizontal: true, vertical: true)
    }
}

private struct PulseModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}
