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

    func stopRecordingAndTranscribe(includePunctuation: Bool, initialPrompt: String? = nil) async -> String? {
        await recorder.stopRecording()

        guard let recordedFile = recordedFile else { return nil }
        guard let whisperContext = whisperContext else { return nil }

        do {
            let samples = try decodeWaveFile(recordedFile)
            let peak = samples.map { abs($0) }.max() ?? 0
            print("[wave] decoded \(samples.count) samples, peak amplitude: \(peak)")
            await whisperContext.fullTranscribe(samples: samples, initialPrompt: initialPrompt)
            let text = await whisperContext.getTranscription()
            print("[wave] raw transcription: '\(text)'")
            let cleaned = Self.clean(text, includePunctuation: includePunctuation)
            print("[wave] cleaned: '\(cleaned ?? "nil — nothing to paste")'")
            return cleaned
        } catch {
            print("[wave] transcription error: \(error)")
            return nil
        }
    }

    func stopRecordingAndTranscribeWithGroq(apiKey: String, model: String, includePunctuation: Bool, initialPrompt: String? = nil) async -> String? {
        await recorder.stopRecording()
        guard let recordedFile = recordedFile else { return nil }
        guard let fileData = try? Data(contentsOf: recordedFile) else { return nil }

        let url = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ string: String) { body.append(string.data(using: .utf8)!) }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n")
        append("Content-Type: audio/wav\r\n\r\n")
        body.append(fileData)
        append("\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append(model)
        append("\r\n")

        if let prompt = initialPrompt {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            append(prompt)
            append("\r\n")
        }

        append("--\(boundary)--\r\n")
        request.httpBody = body

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            struct GroqResponse: Decodable { let text: String }
            let response = try JSONDecoder().decode(GroqResponse.self, from: data)
            print("[wave] groq raw: '\(response.text)'")
            let cleaned = Self.clean(response.text, includePunctuation: includePunctuation)
            print("[wave] groq cleaned: '\(cleaned ?? "nil — nothing to paste")'")
            return cleaned
        } catch {
            print("[wave] groq error: \(error)")
            return nil
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
