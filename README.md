<img width="100%" alt="banner" src="https://github.com/user-attachments/assets/02346b6f-a28f-4df4-b625-d44da35d9385" />

---

## Description

Wave is a lightweight, native macOS dictation app focused on fast voice-to-text workflows with minimal UI overhead. Press a shortcut, speak, and your words are instantly pasted at the cursor. Supports on-device transcription via Whisper and cloud transcription via Groq, plus an AI Mode that sends your voice to an LLM and pastes the response directly.

## Features

- **Dictation** — global shortcut triggers recording; transcription is pasted at the active cursor
- **Push to Talk or Toggle** — hold to record and release, or press once to start and again to stop
- **Local transcription** — on-device Whisper inference, no internet required
- **Groq cloud transcription** — faster cloud-based transcription via the Groq API
- **AI Mode** — separate shortcut sends your voice to an LLM and pastes a direct answer
- **Snippets** — save reusable text snippets; AI Mode is aware of them
- **Dictation history** — recent transcriptions with right-click copy
- **Language selection** — auto-detect or set a specific language (ISO 639-1)
- **Custom vocabulary** — bias the model toward specific words and names
- **Microphone selection** — choose any input device or use the system default

## Default shortcuts

| Action | Default |
|---|---|
| Dictation | `Fn` |
| AI Mode | `Right Option` |

Both shortcuts are fully customizable in Settings → Shortcut.

## Quick start

Download the latest DMG from [Releases](https://github.com/mxvsh/wave/releases/latest).

Releases are distributed as signed, notarized DMGs.

## Build from source

```bash
make build
```

```bash
open build/Build/Products/Release/Wave.app
```

Or launch from Xcode — open `Wave.xcodeproj`, select the `Wave` scheme, and run.

## Signed releases

GitHub Actions builds signed and notarized release DMGs for tags matching `v*.*.*`.

Required repository secrets:

- `BUILD_CERTIFICATE_BASE64` — base64-encoded `Developer ID Application` `.p12`
- `P12_PASSWORD` — password for the `.p12`
- `KEYCHAIN_PASSWORD` — temporary CI keychain password
- `APPLE_ID` — Apple ID email used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD` — app-specific password for notarization
- `APPLE_TEAM_ID` — Apple Developer Team ID
- `SPARKLE_PRIVATE_KEY` — Sparkle EdDSA private key for appcast generation

## Roadmap

- [x] Toggle and Push to Talk recording modes
- [x] Local offline transcription with Whisper
- [x] Groq cloud transcription
- [x] AI Mode with LLM response via Groq
- [x] Custom dictionary / vocabulary
- [x] Language selection
- [x] Dictation history with copy
- [x] Snippets with AI awareness
- [x] Microphone selection
- [ ] App-specific behavior profiles
- [ ] Quality presets for speed vs accuracy

## Support

Join the [Discord](https://discord.gg/6YznRVc23J) community for feedback and help.
For bug reports and feature requests, open a GitHub issue.

## Credits

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) — local speech-to-text inference
- [Sparkle](https://sparkle-project.org/) — macOS auto-update framework
- [PhosphorSwift](https://github.com/phosphor-icons/swift) — icon library

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup and expectations.
