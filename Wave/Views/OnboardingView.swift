import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i <= step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Spacer()

            switch step {
            case 0:
                welcomeStep
            case 1:
                microphoneStep
            case 2:
                accessibilityStep
            case 3:
                modelStep
            default:
                EmptyView()
            }

            Spacer()
        }
        .frame(width: 420, height: 340)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Welcome to wave")
                .font(.title2.bold())
            Text("Background dictation powered by local AI.\nLet's set things up.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Get Started") { step = 1 }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Microphone Access")
                .font(.title2.bold())
            Text("wave needs your microphone to\ncapture speech for transcription.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                if PermissionService.isMicrophoneAuthorized() {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Button("Next") { step = 2 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Grant Access") {
                        Task {
                            _ = await PermissionService.requestMicrophoneAccess()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Skip") { step = 2 }
                        .buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Accessibility Access")
                .font(.title2.bold())
            Text("Required for global shortcuts and\nauto-paste into any app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                if PermissionService.isAccessibilityGranted() {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Button("Next") { step = 3 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Open Settings") {
                        PermissionService.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Skip") { step = 3 }
                        .buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
        }
    }

    private var modelStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Choose a Model")
                .font(.title2.bold())
            Text("Download a whisper model or locate\none you already have.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Set Up Model") {
                appState.isOnboardingComplete = true
                appState.showOnboarding = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
