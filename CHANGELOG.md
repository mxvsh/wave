# Changelog

## [0.3.3](https://github.com/mxvsh/wave/compare/v0.3.2...v0.3.3) (2026-03-30)

### Bug Fixes

* suppress clipboard history recording during paste ([1ace2d3](https://github.com/mxvsh/wave/commit/1ace2d33e5a8f9b6e986522a3a5ca5f043779d8a))

## [0.3.2](https://github.com/mxvsh/wave/compare/v0.3.1...v0.3.2) (2026-03-30)

### Features

* add clear history option with confirmation dialog ([6b25789](https://github.com/mxvsh/wave/commit/6b257891c80c479453436df13482cff0cd57517a))

### Bug Fixes

* correct argument labels in PasteService ([033de68](https://github.com/mxvsh/wave/commit/033de6893be524bb136a473487403232ebbe5eb1))
* use Cmd+V fallback for paste to support terminal and web apps ([1a18850](https://github.com/mxvsh/wave/commit/1a18850f9753ba4b7aea8432d367e017c865bc02))

## [0.3.1](https://github.com/mxvsh/wave/compare/v0.3.0...v0.3.1) (2026-03-30)

### Features

* add option to disable pill during idle state ([a0ade79](https://github.com/mxvsh/wave/commit/a0ade79aba93409e8c2a3c3640d63efa08776dea))
* add pill hover tooltip and press-and-hold to speak ([cef8c77](https://github.com/mxvsh/wave/commit/cef8c77d54913d4fe7e6a2a4fef9f32d5784e6b9))
* move groq section to models tab with masked key display ([d9e2e8b](https://github.com/mxvsh/wave/commit/d9e2e8b9ee3d7856c749acf02826bab53c4c53a0))
* open general settings from menu bar and fix shortcuts label ([bd6baf5](https://github.com/mxvsh/wave/commit/bd6baf50b9ffb7a5cf884f8f5d8fa92bcba08f25))
* selection mode ([54a78b6](https://github.com/mxvsh/wave/commit/54a78b69c15bb8f2c9d6bfca08b4d82225e059cf))

### Bug Fixes

* restart hotkey service when accessibility permission is granted without requiring relaunch ([f29f84d](https://github.com/mxvsh/wave/commit/f29f84d))
* resolve infinite recursion crash in hideOverlayIfIdle ([57f4946](https://github.com/mxvsh/wave/commit/57f4946419d009cf3a240615ef77101638633f04))
* use main run loop for event tap so hotkey works on first launch after update ([10ac898](https://github.com/mxvsh/wave/commit/10ac8989fc3b9805e91007c4625c36fc655ab0bb))

## [0.3.0](https://github.com/mxvsh/wave/compare/v0.2.12...v0.3.0) (2026-03-30)

### Features

* AI Mode with separate shortcut, colored wave overlay, and LLM response via Groq
* Snippets — save reusable text snippets with name and value; AI Mode is aware of them
* Groq cloud transcription with API key verification and model fetching
* Language selection for transcription (auto-detect or ISO 639-1)
* Sidebar redesign using NavigationSplitView with Settings and Help sections
* LLM model picker with pricing table
* LLM system prompt customizable in Models settings
* Recent transcriptions in menu bar (up to 7, click to copy)
* Dictation history limited to 10 most recent on home page
* About and How to Use pages in sidebar
* Brand accent color (#7b6ef6) applied app-wide

### Bug Fixes

* Cmd+Z and Cmd+A now work correctly in text fields
* Left vs Right modifier keys correctly distinguished in shortcut detection
* Shortcut recorder saves combo on key press, confirmed with Enter
* App size reduced by removing PhosphorSwift bundle (84MB)

## [0.2.12](https://github.com/mxvsh/wave/compare/v0.2.11...v0.2.12) (2026-03-19)

### Bug Fixes

* set MACOSX_DEPLOYMENT_TARGET to 14 ([7c3171f](https://github.com/mxvsh/wave/commit/7c3171feb3da2faaf3e21c194f47c22638d9b670))

## [0.2.11](https://github.com/mxvsh/wave/compare/v0.2.10...v0.2.11) (2026-03-17)

## [0.2.10](https://github.com/mxvsh/wave/compare/v0.2.9...v0.2.10) (2026-03-11)

### Bug Fixes

* remove duplicate transcribe call ([ed013f7](https://github.com/mxvsh/wave/commit/ed013f799fbc6a4539679b3b346a0ab8087bec51))

## [0.2.9](https://github.com/mxvsh/wave/compare/v0.2.8...v0.2.9) (2026-03-11)

### Features

* mute system audio during dictation ([#3](https://github.com/mxvsh/wave/issues/3)) ([9c6dc44](https://github.com/mxvsh/wave/commit/9c6dc447b470292baa30c19f09c71dd3c6926423))

## [0.2.8](https://github.com/mxvsh/wave/compare/v0.2.7...v0.2.8) (2026-03-08)

### Bug Fixes

* bump CFBundleVersion alongside marketing version on release ([d2fa1d9](https://github.com/mxvsh/wave/commit/d2fa1d901ddc7a4ccd6ec2120306fe047a6f729e))
* include Info.plist in release version bump hook ([a725bf5](https://github.com/mxvsh/wave/commit/a725bf5032a949ba0e60b164fb463d7b08d7e113))
* resolve menu bar window, onboarding mic stuck, and debug bundle ID ([93a0f23](https://github.com/mxvsh/wave/commit/93a0f23e0f90ce525fa4062123887778f62fc51e))

## [0.2.7](https://github.com/mxvsh/wave/compare/v0.2.6...v0.2.7) (2026-03-08)

### Bug Fixes

* `Combine` import ([8b1cc99](https://github.com/mxvsh/wave/commit/8b1cc99f6437548242c1e40f9cd82a9678af6d60))

* docs: update contributing.md (b20c303)
* chore: separate debug package (b9abeac)
* feat: add live permission gating section to settings (9c9d9f5)

## [0.2.5](https://github.com/mxvsh/wave/compare/v0.2.4...v0.2.5) (2026-03-08)

### Bug Fixes

* **ci:** use macos-26 ([7870581](https://github.com/mxvsh/wave/commit/7870581827950dc4f398f9d554bab35e652da308))

## [0.2.4](https://github.com/mxvsh/wave/compare/v0.2.3...v0.2.4) (2026-03-08)

### Bug Fixes

* `v` prefix in Info.plist ([a29dda6](https://github.com/mxvsh/wave/commit/a29dda629907a3df985b7850eb677d94c29d4234))

## [0.2.3](https://github.com/mxvsh/wave/compare/v0.2.2...v0.2.3) (2026-03-08)

## [0.2.2](https://github.com/mxvsh/wave/compare/v0.2.1...v0.2.2) (2026-03-07)

### Bug Fixes

* download DMG directly into release-dir for appcast generation ([89e07f5](https://github.com/mxvsh/wave/commit/89e07f5d3bfac9877beb9af9336745da4a76d576))

## [0.2.1](https://github.com/mxvsh/wave/compare/v0.2.0...v0.2.1) (2026-03-07)
