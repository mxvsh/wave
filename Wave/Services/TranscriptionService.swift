import Foundation
import AVFoundation

@MainActor
final class TranscriptionService: NSObject, AVAudioRecorderDelegate {
    private var whisperContext: WhisperContext?
    private let recorder = AudioRecorder()
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

    func stopRecordingAndTranscribe() async -> String? {
        await recorder.stopRecording()

        guard let recordedFile = recordedFile else { return nil }
        guard let whisperContext = whisperContext else { return nil }

        do {
            let samples = try decodeWaveFile(recordedFile)
            let peak = samples.map { abs($0) }.max() ?? 0
            print("[wave] decoded \(samples.count) samples, peak amplitude: \(peak)")
            await whisperContext.fullTranscribe(samples: samples)
            let text = await whisperContext.getTranscription()
            print("[wave] raw transcription: '\(text)'")
            let cleaned = Self.clean(text)
            print("[wave] cleaned: '\(cleaned ?? "nil — nothing to paste")'")
            return cleaned
        } catch {
            print("[wave] transcription error: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private static let noiseTokens: Set<String> = [
        "[BLANK_AUDIO]", "[SILENCE]", "(silence)", "[Music]", "[MUSIC]",
        "(Music)", "(music)", "[noise]", "[NOISE]", "(noise)",
    ]

    private static func clean(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || noiseTokens.contains(trimmed) { return nil }
        // Strip leading/trailing noise tokens that sometimes appear alongside real text
        var result = trimmed
        for token in noiseTokens {
            result = result.replacingOccurrences(of: token, with: "")
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
