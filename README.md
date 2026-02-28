
<img width="2560" height="1440" alt="wave-banner" src="https://github.com/user-attachments/assets/83c1bbfb-2c4d-4cfe-a351-a88875f06172" />

---

## Description

Wave is a lightweight, native macOS dictation app focused on fast voice-to-text workflows with local transcription and minimal UI overhead. Speak with a global shortcut, transcribe locally with Whisper, and paste instantly into the active app.


## Quick start

Build it yourself for free from source, or get the ready-to-use app on [Gumroad](https://monawwar.gumroad.com/l/wave) with lifetime updates for just **$5.99**.

## Build from source

Build the app:

```bash
make build
```

Open:
```bash
open build/Build/Products/Release/Wave.app
```

Or launch from Xcode:
- Open `Wave.xcodeproj`
- Select scheme `Wave`
- Run

## Notes

- This repository is intended for personal/local use builds.
- No hosted update/release setup is required to run the app locally.

## Roadmap

- [x] Toggle-style recording mode from settings
- [x] Local/offline transcription with Whisper models
- [ ] Add optional text cleanup modes (punctuation, capitalization, concise cleanup)
- [ ] Add app-specific behavior profiles (different formatting for IDE/chat/docs)
- [ ] Add recent dictation history with one-click reinsert/copy
- [ ] Add quality presets for speed vs accuracy
- [ ] Add AI agent mode: speak natural-language instructions to write or edit selected text

## Support

For any feedback or assistance, join the [Discord](https://discord.gg/6YznRVc23J) community.  
For feature requests, bug reports, or help, you can also create a GitHub issue.

## Credits

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) for local speech-to-text inference
- [Sparkle](https://sparkle-project.org/) for macOS update framework support
- Apple SwiftUI/AppKit ecosystem for native macOS app foundations

## Contributing

Contributions are welcome, including AI-assisted feature work.

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, expectations, and validation checklist.
