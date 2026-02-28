# Contributing

Thanks for contributing to Wave.

This project is maintained as a personal-use native macOS app. Contributions should prioritize simple, reliable behavior and minimal UI/UX friction.

## Local Setup

1. Open `Wave.xcodeproj` in Xcode.
2. Select scheme `Wave`.
3. Build locally:

```bash
make build
```

If needed, rebuild from scratch:

```bash
make clean && make build
```

You can run the app from:
- Xcode (`Run`)
- `build/Build/Products/Release/Wave.app`

## Personal-Use Release Build

For a local personal-use release flow:

```bash
make release
```

## What To Focus On

- Dictation reliability (hotkey -> record -> transcribe -> paste)
- Lightweight native UX
- Safe single-instance behavior
- Clear onboarding and settings behavior

## Using AI To Build Features

AI-assisted contribution is welcome. If you use AI tools:

1. Keep prompts specific to this codebase and file paths.
2. Ask AI for incremental changes, not large rewrites.
3. Verify all generated code manually before committing.
4. Build and run the app after changes.
5. Confirm no regressions in:
   - global shortcut capture
   - overlay status behavior
   - text paste flow
   - onboarding/state persistence

When proposing AI-generated changes, include:
- what files changed
- what behavior changed
- how you validated locally

## PR/Change Notes

When submitting changes, keep notes concise:

- Problem being solved
- Implementation summary
- Validation steps run
