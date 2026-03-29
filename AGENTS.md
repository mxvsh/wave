# Wave — CLAUDE.md

Wave is a lightweight macOS dictation app. Press a shortcut, speak, and your words are transcribed and pasted at the cursor. It supports on-device Whisper and Groq cloud transcription, plus an AI Mode that sends the transcription to an LLM and pastes the response.

---

## Architecture

- **Single source of truth.** All app state lives in one `@Observable @MainActor` class (`AppState`). Do not create additional observable singletons or pass state through multiple layers.
- **Services are owned by `AppState`**, not created in views. Views call methods on the state object; they never instantiate services directly.
- **All persistent settings** are stored in `UserDefaults` via `didSet` on the property. No other persistence mechanism.
- **Views are display-only.** Business logic belongs in `AppState` or a service. If a view is doing more than formatting and rendering, move the logic out.

---

## Design system

Follow these rules consistently. Do not invent new patterns when an existing one covers the case.

**Typography**
- Section headers: size 11, medium weight, secondary color, uppercase
- Row labels / body: size 13
- Secondary detail: size 12, secondary color
- Monospaced inputs (API keys, code): size 12, monospaced design
- Captions / metadata: size 11

**Spacing**
- Page padding: 16pt on all sides
- Between sections: 20pt
- Within a section: 8pt

**Backgrounds**
- Card / row: `.quaternary.opacity(0.5)` with `RoundedRectangle(cornerRadius: 8)`
- Standard button: `.quaternary` with `RoundedRectangle(cornerRadius: 6)`
- Primary action button: `.blue.opacity(0.15)` background, `.blue` foreground, `RoundedRectangle(cornerRadius: 7)`

**Buttons**
- Always `.buttonStyle(.plain)`
- Font: size 12, medium weight, rounded design
- Standard padding: 10pt horizontal, 4pt vertical
- Primary padding: 10pt horizontal, 5pt vertical

**Sections**
Every settings section follows this exact structure: uppercase label at size 11 in secondary color, followed by the content at 8pt spacing. Reuse the existing `section(_:content:)` helper found in each settings view — do not create a new one.

---

## Navigation

The sidebar is a `NavigationSplitView` with a fixed-width column. Items are grouped into sections. The detail pane renders the selected view.

- Settings pages (General, Shortcut, Models) are **not scrollable** — use a plain `VStack` with padding.
- The window size is **fixed**. Do not make it resizable or change its dimensions without explicit instruction.
- Sidebar icons use **PhosphorSwift** (`Ph.<name>.regular`), always constrained to `frame(width: 16, height: 16)`. Without the frame they stretch. Do not use SF Symbols for sidebar icons.

---

## Shortcuts

- Distinguish Left vs Right modifier keys explicitly — flag bitmasks alone (`maskAlternate`, `maskCommand`) are identical for both sides. Track the exact keyCodes being held to tell them apart.
- The shortcut recorder persists the pressed combination (`savedCombo`) after the user releases keys, so Enter can confirm it even after release. Regular key presses save immediately without needing Enter.

---

## MenuBar

Keep the menu bar menu lean and in this order:
1. Status (idle / recording / transcribing / error)
2. Recent Transcriptions submenu (max 7, copy on click, truncate long text)
3. Check for Updates
4. Settings (⌘,)
5. Quit (⌘Q)

Dividers between logical groups, not between every item.

---

## Code style

- No docstrings or comments on code you didn't write or change.
- No error handling for internal code paths — only at system boundaries (user input, external APIs).
- No helpers or abstractions for one-off operations.
- No speculative features, flags, or "future-proofing."
- Prefer editing existing files over creating new ones.
- If something is unused, delete it — don't rename it with a leading underscore or leave a comment.

---

## Things never to do

- Do not add `ScrollView` to settings pages.
- Do not mock services in a way that diverges from production behavior.
- Do not re-add `CommandGroup(replacing: .undoRedo) {}` — it breaks Cmd+Z in text fields.
- Do not remove the menu-cleaning logic in `applicationDidBecomeActive` — it removes ghost headers left by SwiftUI `CommandGroup` replacements.
- Do not push to main or create PRs without being explicitly asked.
