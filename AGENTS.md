# AGENTS.md

## Project Overview

Wave is a native macOS dictation app.

Core flow:
1. User triggers global shortcut.
2. App records microphone audio.
3. Audio is transcribed locally with Whisper.
4. Transcribed text is pasted into the currently focused app.

Primary goals:
- Fast and lightweight
- Native macOS feel (SwiftUI + AppKit)
- Minimal UI friction
- Personal-use source build

## Tech Stack

- Language: Swift
- UI: SwiftUI (with AppKit where needed)
- Hotkeys/events: CGEvent tap
- Transcription: local Whisper via bundled `whisper.xcframework`
- Project: Xcode (`Wave.xcodeproj`)

## Important Paths

- App entry: `Wave/waveApp.swift`
- App state: `Wave/AppState.swift`
- Services:
  - `Wave/Services/HotkeyService.swift`
  - `Wave/Services/AudioRecorder.swift`
  - `Wave/Services/TranscriptionService.swift`
  - `Wave/Services/WhisperContext.swift`
  - `Wave/Services/UpdaterService.swift`
- Views:
  - `Wave/Views/HomeView.swift`
  - `Wave/Views/OverlayView.swift`
  - `Wave/Views/OverlayPanel.swift`
  - `Wave/Views/OnboardingView.swift`
  - `Wave/Views/ModelPickerView.swift`
  - `Wave/Views/ShortcutRecorderView.swift`
- Build scripts:
  - `Makefile`
  - `scripts/release.sh`

## Current Product Behavior

- Single-instance app: launching a second instance should focus the first and exit.
- App appears as a regular macOS app (menu bar app name + Cmd+Tab presence).
- Overlay shows recording/transcribing/error status.
- Onboarding completion tracked in `UserDefaults` key: `isOnboardingComplete`.
- Sparkle updater is wired; feed URL and key come from app Info.plist/build settings.

## Build & Run

Build:
```bash
make build
```

If incremental build says up to date:
```bash
make clean && make build
```

Run app:
- Open `build/Build/Products/Release/Wave.app`
- Or run from Xcode with scheme `Wave`

## Contributor Guardrails

- Preserve low-friction dictation flow (hotkey -> speak -> paste).
- Avoid introducing heavy runtime dependencies.
- Prefer native APIs over external wrappers.
- Keep UI minimal and functional; avoid unnecessary complexity.
- Validate behavior for:
  - Global hotkey capture
  - Focus-safe overlay behavior
  - Paste reliability
  - Single-instance launch logic

## Near-Term Feature Direction

- Optional text cleanup modes (punctuation/capitalization)
- App-specific formatting profiles
- Dictation history/reuse
- AI agent mode for natural-language editing of selected text
