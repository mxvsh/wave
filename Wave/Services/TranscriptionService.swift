import Foundation
import AVFoundation

@MainActor
final class TranscriptionService: NSObject, AVAudioRecorderDelegate {
    private var whisperContext: WhisperContext?
    private let recorder = AudioRecorder()
    private let groqService = GroqTranscriptionService()
    private var recordedFile: URL?
    private var onTranscription: ((String) -> Void)?
    private var onError: ((String) -> Void)?

    func loadModel(path: String) async throws {
        whisperContext = try WhisperContext.createContext(path: path)
    }

    func unloadModel() {
        whisperContext = nil
    }

    var isModelLoaded: Bool {
        whisperContext != nil
    }

    func startRecording() async throws {
        let granted = await PermissionService.requestMicrophoneAccess()
        guard granted else { throw RecordingError.microphonePermissionDenied }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("wave_recording.wav")
        recordedFile = file
        try await recorder.startRecording(toOutputFile: file, delegate: self)
    }

    enum RecordingError: LocalizedError {
        case microphonePermissionDenied
        var errorDescription: String? { "Microphone access denied" }
    }

    enum TranscriptionError: LocalizedError {
        case recordingMissing
        case modelNotLoaded
        case groqAPIKeyMissing

        var errorDescription: String? {
            switch self {
            case .recordingMissing:
                return "Recording file missing"
            case .modelNotLoaded:
                return "No model loaded"
            case .groqAPIKeyMissing:
                return "Groq API key missing"
            }
        }
    }

    func stopRecordingAndTranscribe(
        includePunctuation: Bool,
        provider: TranscriptionProvider,
        groqAPIKey: String,
        groqModel: GroqWhisperModel,
        initialPrompt: String? = nil
    ) async throws -> String? {
        await recorder.stopRecording()

        guard let recordedFile = recordedFile else {
            throw TranscriptionError.recordingMissing
        }

        do {
            let text: String

            switch provider {
            case .localWhisper:
                guard let whisperContext = whisperContext else {
                    throw TranscriptionError.modelNotLoaded
                }

                let samples = try decodeWaveFile(recordedFile)
                let peak = samples.map { abs($0) }.max() ?? 0
                print("[wave] decoded \(samples.count) samples, peak amplitude: \(peak)")
                await whisperContext.fullTranscribe(samples: samples, initialPrompt: initialPrompt)
                text = await whisperContext.getTranscription()
            case .groqAPI:
                let trimmedAPIKey = groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedAPIKey.isEmpty else {
                    throw TranscriptionError.groqAPIKeyMissing
                }

                text = try await groqService.transcribe(
                    fileURL: recordedFile,
                    apiKey: trimmedAPIKey,
                    model: groqModel,
                    prompt: initialPrompt
                )
            }

            print("[wave] raw transcription: '\(text)'")
            let cleaned = Self.clean(text, includePunctuation: includePunctuation)
            print("[wave] cleaned: '\(cleaned ?? "nil — nothing to paste")'")
            return cleaned
        } catch {
            print("[wave] transcription error: \(error)")
            throw error
        }
    }

    // MARK: - Helpers

    private static let noiseTokens: Set<String> = [
        "[BLANK_AUDIO]", "[SILENCE]", "(silence)", "[Music]", "[MUSIC]",
        "(Music)", "(music)", "[noise]", "[NOISE]", "(noise)",
    ]

    private static func clean(_ raw: String, includePunctuation: Bool) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || noiseTokens.contains(trimmed) { return nil }
        // Strip leading/trailing noise tokens that sometimes appear alongside real text
        var result = trimmed
        for token in noiseTokens {
            result = result.replacingOccurrences(of: token, with: "")
        }
        if !includePunctuation {
            result = result
                .components(separatedBy: .punctuationCharacters)
                .joined(separator: " ")
            result = result.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    // MARK: - AVAudioRecorderDelegate

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error.localizedDescription)")
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Recording finished
    }
}
