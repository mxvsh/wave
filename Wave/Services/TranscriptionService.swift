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

    func audioLevel() async -> Float {
        await recorder.currentLevel()
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

    func stopRecordingAndTranscribe(includePunctuation: Bool, language: String? = nil, initialPrompt: String? = nil) async -> String? {
        await recorder.stopRecording()

        guard let recordedFile = recordedFile else { return nil }
        guard let whisperContext = whisperContext else { return nil }

        do {
            let samples = try decodeWaveFile(recordedFile)
            let peak = samples.map { abs($0) }.max() ?? 0
            print("[wave] decoded \(samples.count) samples, peak amplitude: \(peak)")
            await whisperContext.fullTranscribe(samples: samples, language: language, initialPrompt: initialPrompt)
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

    func stopRecordingAndTranscribeWithGroq(apiKey: String, model: String, includePunctuation: Bool, language: String? = nil, initialPrompt: String? = nil) async -> String? {
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

        if let language {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            append(language)
            append("\r\n")
        }

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

    struct AIResult {
        let text: String?
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        let totalTime: Double
    }

    func sendToAI(text: String, apiKey: String, model: String, systemPrompt: String) async -> AIResult {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ]
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return AIResult(text: nil, promptTokens: 0, completionTokens: 0, totalTokens: 0, totalTime: 0)
        }
        request.httpBody = httpBody

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            struct Message: Decodable { let content: String }
            struct Choice: Decodable { let message: Message }
            struct Usage: Decodable {
                let promptTokens: Int
                let completionTokens: Int
                let totalTokens: Int
                let totalTime: Double
                enum CodingKeys: String, CodingKey {
                    case promptTokens = "prompt_tokens"
                    case completionTokens = "completion_tokens"
                    case totalTokens = "total_tokens"
                    case totalTime = "total_time"
                }
            }
            struct AIResponse: Decodable {
                let choices: [Choice]
                let usage: Usage?
            }

            let response = try JSONDecoder().decode(AIResponse.self, from: data)
            let result = response.choices.first?.message.content
            let usage = response.usage
            print("[wave] AI response: '\(result ?? "nil")' tokens=\(usage?.totalTokens ?? 0)")
            return AIResult(
                text: result,
                promptTokens: usage?.promptTokens ?? 0,
                completionTokens: usage?.completionTokens ?? 0,
                totalTokens: usage?.totalTokens ?? 0,
                totalTime: usage?.totalTime ?? 0
            )
        } catch {
            print("[wave] AI error: \(error)")
            return AIResult(text: nil, promptTokens: 0, completionTokens: 0, totalTokens: 0, totalTime: 0)
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
