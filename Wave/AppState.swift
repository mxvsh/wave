import Foundation
import SwiftUI

enum DictationMode: String, CaseIterable {
    case pushToTalk = "Push to Talk"
    case toggle = "Toggle"
}

enum TranscriptionProvider: String {
    case local = "local"
    case groq = "groq"
}

enum AppStatus: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)
}

@Observable
@MainActor
final class AppState {
    // MARK: - State
    var status: AppStatus = .idle
    var isOnboardingComplete: Bool {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete") }
    }
    var showOnboarding = false

    // MARK: - Settings
    var dictationMode: DictationMode {
        didSet { UserDefaults.standard.set(dictationMode.rawValue, forKey: "dictationMode") }
    }
    var hotkeyKeyCode: UInt16 {
        didSet { UserDefaults.standard.set(Int(hotkeyKeyCode), forKey: "hotkeyKeyCode") }
    }
    var hotkeyModifiers: UInt64 {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers") }
    }
    var includePunctuation: Bool {
        didSet { UserDefaults.standard.set(includePunctuation, forKey: "includePunctuation") }
    }
    var muteSystemAudio: Bool {
        didSet { UserDefaults.standard.set(muteSystemAudio, forKey: "muteSystemAudio") }
    }
    var customVocabulary: [String] {
        didSet { UserDefaults.standard.set(customVocabulary, forKey: "customVocabulary") }
    }
    var transcriptionProvider: TranscriptionProvider {
        didSet {
            UserDefaults.standard.set(transcriptionProvider.rawValue, forKey: "transcriptionProvider")
            if transcriptionProvider == .groq {
                transcriptionService.unloadModel()
                isModelLoaded = false
            }
        }
    }
    var groqAPIKey: String {
        didSet { UserDefaults.standard.set(groqAPIKey, forKey: "groqAPIKey") }
    }
    var groqModel: String {
        didSet { UserDefaults.standard.set(groqModel, forKey: "groqModel") }
    }

    // MARK: - Services
    let modelManager = ModelManager()
    let transcriptionService = TranscriptionService()
    let hotkeyService = HotkeyService()
    let historyManager = HistoryManager()
    let microphoneManager = MicrophoneManager()
    var isModelLoaded = false   // tracked by @Observable — TranscriptionService is not

    var isReady: Bool {
        switch transcriptionProvider {
        case .local: return isModelLoaded
        case .groq: return !groqAPIKey.isEmpty
        }
    }

    // MARK: - Overlay
    var overlayPanel: OverlayPanel?

    // MARK: - Private
    private var isKeyHeld = false

    var shortcutDisplayString: String {
        KeyCodeMapping.displayString(
            keyCode: hotkeyKeyCode,
            modifiers: CGEventFlags(rawValue: hotkeyModifiers)
        )
    }

    init() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        dictationMode = DictationMode(rawValue: UserDefaults.standard.string(forKey: "dictationMode") ?? "") ?? .pushToTalk
        hotkeyKeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        hotkeyModifiers = UInt64(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        if UserDefaults.standard.object(forKey: "includePunctuation") == nil {
            includePunctuation = true
        } else {
            includePunctuation = UserDefaults.standard.bool(forKey: "includePunctuation")
        }
        muteSystemAudio = UserDefaults.standard.bool(forKey: "muteSystemAudio")
        customVocabulary = UserDefaults.standard.stringArray(forKey: "customVocabulary") ?? []
        transcriptionProvider = TranscriptionProvider(rawValue: UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "") ?? .local
        groqAPIKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        groqModel = UserDefaults.standard.string(forKey: "groqModel") ?? "whisper-large-v3-turbo"

        // Default shortcut: Right Option
        if hotkeyKeyCode == 0 && hotkeyModifiers == 0 {
            hotkeyKeyCode = 61 // kVK_RightOption
            hotkeyModifiers = CGEventFlags.maskAlternate.rawValue
        }

        if !isOnboardingComplete {
            showOnboarding = true
        }

        Task {
            await loadSelectedModel()
            setupHotkey()
        }
    }

    func setupHotkey() {
        hotkeyService.targetKeyCode = CGKeyCode(hotkeyKeyCode)
        hotkeyService.targetModifiers = CGEventFlags(rawValue: hotkeyModifiers)

        hotkeyService.onKeyDown = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch self.dictationMode {
                case .pushToTalk:
                    if self.status == .idle {
                        self.isKeyHeld = true
                        Task { await self.startDictation() }
                    }
                case .toggle:
                    if self.status == .idle {
                        Task { await self.startDictation() }
                    } else if self.status == .recording {
                        Task { await self.stopDictationAndPaste() }
                    }
                }
            }
        }

        hotkeyService.onKeyUp = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.dictationMode == .pushToTalk && self.isKeyHeld && self.status == .recording {
                    self.isKeyHeld = false
                    Task { await self.stopDictationAndPaste() }
                }
            }
        }

        hotkeyService.start()
    }

    func startDictation() async {
        guard isReady else {
            status = .error(transcriptionProvider == .groq ? "Groq API key required" : "No model loaded")
            try? await Task.sleep(for: .seconds(2))
            status = .idle
            return
        }

        do {
            status = .recording
            showOverlay()
            if muteSystemAudio { SystemAudioDucker.duck() }
            try await transcriptionService.startRecording()
        } catch {
            if muteSystemAudio { SystemAudioDucker.restore() }
            status = .error("Recording failed")
            hideOverlay()
            try? await Task.sleep(for: .seconds(2))
            status = .idle
        }
    }

    func stopDictationAndPaste() async {
        status = .transcribing
        updateOverlay()

        let prompt = customVocabulary.isEmpty ? nil : customVocabulary.joined(separator: ", ")
        let text: String?
        switch transcriptionProvider {
        case .local:
            text = await transcriptionService.stopRecordingAndTranscribe(includePunctuation: includePunctuation, initialPrompt: prompt)
        case .groq:
            text = await transcriptionService.stopRecordingAndTranscribeWithGroq(
                apiKey: groqAPIKey,
                model: groqModel,
                includePunctuation: includePunctuation,
                initialPrompt: prompt
            )
        }
        if muteSystemAudio { SystemAudioDucker.restore() }

        hideOverlay()

        if let text = text, !text.isEmpty {
            print("[wave] pasting: '\(text)'")
            historyManager.add(text)
            try? await Task.sleep(for: .milliseconds(100))
            PasteService.paste(text: text)
        } else {
            print("[wave] nothing to paste")
        }

        status = .idle
    }

    func loadSelectedModel() async {
        guard let path = modelManager.selectedModelPath else { return }
        do {
            try await transcriptionService.loadModel(path: path)
            isModelLoaded = true
        } catch {
            print("Failed to load model: \(error)")
            isModelLoaded = false
            status = .error("Failed to load model")
            try? await Task.sleep(for: .seconds(2))
            status = .idle
        }
    }

    // MARK: - Overlay

    func showOverlay() {
        if overlayPanel == nil {
            overlayPanel = OverlayPanel()
        }
        overlayPanel?.showOverlay(status: status)
    }

    func updateOverlay() {
        overlayPanel?.showOverlay(status: status)
    }

    func hideOverlay() {
        overlayPanel?.hideOverlay()
    }
}
