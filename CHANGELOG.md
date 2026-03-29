# Changelog

## [0.3.0](https://github.com/mxvsh/wave/compare/v0.2.12...v0.3.0) (2026-03-29)

### Features

* Add Groq provider with API key input and local model delete ([bf422c1](https://github.com/mxvsh/wave/commit/bf422c10c4f7e5e3f3c33ef67d99180ebda995ab))
* add language selector ([d65d70b](https://github.com/mxvsh/wave/commit/d65d70b0473288817a596fea639b08813725f070))
* add microphone selector in settings ([9bddfbc](https://github.com/mxvsh/wave/commit/9bddfbcd9c388238cf343bbbcea8762f8bbd7dfc))
* add persistent bottom bar ([44a3d2e](https://github.com/mxvsh/wave/commit/44a3d2e4a42d824acc24b7c35a1420019d6d67a2))
* add snippet manager ([6876491](https://github.com/mxvsh/wave/commit/687649120ce5527ba6b89820a5fa156d9e7a6ce5))
* Change default hotkey to Right Option ([f1db92c](https://github.com/mxvsh/wave/commit/f1db92cddc7121e498e6234bc38b08256f4e49b6))
* Fix layout issues, remove borders, pin dictionary input to bottom ([68a03ca](https://github.com/mxvsh/wave/commit/68a03ca814825bb3ae7c6fc66403cc912905d1ae))
* llm system prompt and llm model picker ([0f4a8ff](https://github.com/mxvsh/wave/commit/0f4a8ff4ec56de76d2f5c4be878987f1fcc39ad6))
* recent transcriptionoption  in menu bar ([880efaf](https://github.com/mxvsh/wave/commit/880efaf8304312a2d33ee5c74747b80438f74de0))
* Redesign app with NavigationSplitView sidebar, transcription history, and stats ([5a2a5e1](https://github.com/mxvsh/wave/commit/5a2a5e1c6d75d5d782238131d0a5487ff3723396))
* Replace overlay text with compact wave animation ([720b1fa](https://github.com/mxvsh/wave/commit/720b1fa613703077403ab3a878e6cf52fbdfa79a))
* set brand color ([953c5ae](https://github.com/mxvsh/wave/commit/953c5ae3aedfde3d24f3ac4797423cf9ad9dfbc2))

### Bug Fixes

* apply selected mic on startup and before each recording ([3997307](https://github.com/mxvsh/wave/commit/3997307b3ffebfb1b55650325f34d481cc41e5b7))
* Insert transcription via accessibility API instead of clipboard ([041220c](https://github.com/mxvsh/wave/commit/041220c4d6850893e89bca38639968751658da5d))
* **web:** keyboard ui ([1e82f86](https://github.com/mxvsh/wave/commit/1e82f86c8b1691333fc36785e43956a8f6e76cfc))

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
