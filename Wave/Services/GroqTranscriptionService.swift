import Foundation

enum GroqWhisperModel: String, CaseIterable, Identifiable {
    case whisperLargeV3Turbo = "whisper-large-v3-turbo"
    case whisperLargeV3 = "whisper-large-v3"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

struct GroqTranscriptionService {
    private let session: URLSession
    private let endpoint = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func transcribe(fileURL: URL, apiKey: String, model: GroqWhisperModel, prompt: String?) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeBody(fileURL: fileURL, model: model, prompt: prompt, boundary: boundary)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(GroqAPIErrorEnvelope.self, from: data) {
                throw GroqError.api(apiError.error.message)
            }
            throw GroqError.api("Groq request failed with status \(httpResponse.statusCode)")
        }

        do {
            let transcription = try JSONDecoder().decode(GroqTranscriptionResponse.self, from: data)
            return transcription.text
        } catch {
            throw GroqError.invalidResponse
        }
    }

    private func makeBody(fileURL: URL, model: GroqWhisperModel, prompt: String?, boundary: String) throws -> Data {
        let audioData = try Data(contentsOf: fileURL)
        var body = Data()

        appendField(named: "model", value: model.rawValue, boundary: boundary, to: &body)
        appendField(named: "response_format", value: "json", boundary: boundary, to: &body)

        if let prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            appendField(named: "prompt", value: prompt, boundary: boundary, to: &body)
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }

    private func appendField(named name: String, value: String, boundary: String, to body: inout Data) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }
}

private struct GroqTranscriptionResponse: Decodable {
    let text: String
}

private struct GroqAPIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}

enum GroqError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Groq returned an invalid response"
        case .api(let message):
            return message
        }
    }
}
