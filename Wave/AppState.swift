import Foundation
import SwiftUI

enum DictationMode: String, CaseIterable {
    case pushToTalk = "Push to Talk"
    case toggle = "Toggle"
}

enum TranscriptionProvider: String, CaseIterable {
    case localWhisper = "Local Whisper"
    case groqAPI = "Groq API"
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
    var lastTranscription: String?
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
    var transcriptionProvider: TranscriptionProvider {
        didSet { UserDefaults.standard.set(transcriptionProvider.rawValue, forKey: "transcriptionProvider") }
    }
    var groqModel: GroqWhisperModel {
        didSet { UserDefaults.standard.set(groqModel.rawValue, forKey: "groqModel") }
    }
    var groqAPIKey: String {
        didSet {
            let trimmed = groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                KeychainService.delete(account: Self.groqAPIKeyAccount)
            } else {
                _ = KeychainService.save(value: trimmed, account: Self.groqAPIKeyAccount)
            }
        }
    }
    var customVocabulary: [String] {
        didSet { UserDefaults.standard.set(customVocabulary, forKey: "customVocabulary") }
    }

    // MARK: - Services
    let modelManager = ModelManager()
    let transcriptionService = TranscriptionService()
    let hotkeyService = HotkeyService()
    var isModelLoaded = false   // tracked by @Observable — TranscriptionService is not
    var isHotkeyAvailable = false

    // MARK: - Overlay
    var overlayPanel: OverlayPanel?

    // MARK: - Private
    private var isKeyHeld = false
    private static let groqAPIKeyAccount = "groq-api-key"

    var shortcutDisplayString: String {
        KeyCodeMapping.displayString(
            keyCode: hotkeyKeyCode,
            modifiers: CGEventFlags(rawValue: hotkeyModifiers)
        )
    }

    var isReadyToDictate: Bool {
        switch transcriptionProvider {
        case .localWhisper:
            return isModelLoaded
        case .groqAPI:
            return !groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var readyStatusText: String {
        switch transcriptionProvider {
        case .localWhisper:
            return isModelLoaded ? "Ready" : "No model loaded"
        case .groqAPI:
            return isReadyToDictate ? "Ready" : "Groq API key missing"
        }
    }

    init() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        dictationMode = DictationMode(rawValue: UserDefaults.standard.string(forKey: "dictationMode") ?? "") ?? .pushToTalk
        hotkeyKeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        hotkeyModifiers = UInt64(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        transcriptionProvider = TranscriptionProvider(
            rawValue: UserDefaults.standard.string(forKey: "transcriptionProvider") ?? ""
        ) ?? .localWhisper
        groqModel = GroqWhisperModel(
            rawValue: UserDefaults.standard.string(forKey: "groqModel") ?? ""
        ) ?? .whisperLargeV3Turbo
        groqAPIKey = KeychainService.read(account: Self.groqAPIKeyAccount) ?? ""
        if UserDefaults.standard.object(forKey: "includePunctuation") == nil {
            includePunctuation = true
        } else {
            includePunctuation = UserDefaults.standard.bool(forKey: "includePunctuation")
        }
        muteSystemAudio = UserDefaults.standard.bool(forKey: "muteSystemAudio")
        customVocabulary = UserDefaults.standard.stringArray(forKey: "customVocabulary") ?? []

        // Default shortcut: Control + Space
        if hotkeyKeyCode == 0 && hotkeyModifiers == 0 {
            hotkeyKeyCode = 49 // kVK_Space
            hotkeyModifiers = CGEventFlags.maskControl.rawValue
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
        hotkeyService.stop()
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

        isHotkeyAvailable = hotkeyService.start()
    }

    func startDictation() async {
        guard isReadyToDictate else {
            status = .error(readyStatusText)
            try? await Task.sleep(for: .seconds(2))
            status = .idle
            return
        }

        do {
            lastTranscription = nil
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
        let text = await finishDictation(
            shouldPaste: true,
            restoreAudioOnComplete: true
        )
        if let text, !text.isEmpty {
            print("[wave] pasting: '\(text)'")
            try? await Task.sleep(for: .milliseconds(100))
            PasteService.paste(text: text)
        } else {
            print("[wave] nothing to paste")
        }
        status = .idle
    }

    func stopDictationForTest() async {
        let text = await finishDictation(
            shouldPaste: false,
            restoreAudioOnComplete: true
        )
        if text == nil || text?.isEmpty == true {
            print("[wave] nothing to show")
        }
        status = .idle
    }

    func clearSelectedModel() async {
        modelManager.clearSelection()
        await loadSelectedModel()
    }

    func loadSelectedModel() async {
        transcriptionService.unloadModel()
        isModelLoaded = false

        guard let path = modelManager.selectedModelPath else { return }
        do {
            try await transcriptionService.loadModel(path: path)
            isModelLoaded = true
        } catch {
            print("Failed to load model: \(error)")
            isModelLoaded = false
            if transcriptionProvider == .localWhisper {
                status = .error("Failed to load model")
                try? await Task.sleep(for: .seconds(2))
                status = .idle
            }
        }
    }

    private func finishDictation(shouldPaste: Bool, restoreAudioOnComplete: Bool) async -> String? {
        status = .transcribing
        updateOverlay()

        let prompt = customVocabulary.isEmpty ? nil : customVocabulary.joined(separator: ", ")
        let text: String?

        do {
            text = try await transcriptionService.stopRecordingAndTranscribe(
                includePunctuation: includePunctuation,
                provider: transcriptionProvider,
                groqAPIKey: groqAPIKey,
                groqModel: groqModel,
                initialPrompt: prompt
            )
        } catch {
            if restoreAudioOnComplete && muteSystemAudio { SystemAudioDucker.restore() }
            hideOverlay()
            status = .error(error.localizedDescription)
            try? await Task.sleep(for: .seconds(2))
            status = .idle
            return nil
        }

        if restoreAudioOnComplete && muteSystemAudio { SystemAudioDucker.restore() }

        hideOverlay()

        if let text = text, !text.isEmpty {
            lastTranscription = text
            if !shouldPaste {
                return text
            }
        }
        return text
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
