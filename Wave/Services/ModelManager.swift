import Foundation

struct WhisperModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let size: String
    let type: String
    let filename: String
    let url: String

    static let available: [WhisperModel] = [
        WhisperModel(name: "tiny.en", size: "75 MB", type: "English", filename: "ggml-tiny.en.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"),
        WhisperModel(name: "tiny-q5_1", size: "31 MB", type: "English, quantized", filename: "ggml-tiny.en-q5_1.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-q5_1.bin"),
        WhisperModel(name: "base.en", size: "142 MB", type: "English", filename: "ggml-base.en.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"),
        WhisperModel(name: "base-q5_1", size: "57 MB", type: "English, quantized", filename: "ggml-base.en-q5_1.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q5_1.bin"),
        WhisperModel(name: "small.en", size: "466 MB", type: "English", filename: "ggml-small.en.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"),
        WhisperModel(name: "small-q5_1", size: "181 MB", type: "English, quantized", filename: "ggml-small.en-q5_1.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en-q5_1.bin"),
        WhisperModel(name: "medium.en", size: "1.5 GB", type: "English", filename: "ggml-medium.en.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"),
        WhisperModel(name: "medium-q5_0", size: "514 MB", type: "English, quantized", filename: "ggml-medium.en-q5_0.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en-q5_0.bin"),
        WhisperModel(name: "large-v3-turbo", size: "1.5 GB", type: "Multilingual", filename: "ggml-large-v3-turbo.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"),
        WhisperModel(name: "large-v3-turbo-q5_0", size: "547 MB", type: "Multilingual, quantized", filename: "ggml-large-v3-turbo-q5_0.bin",
                     url: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"),
    ]
}

@Observable
final class ModelManager {
    var downloadProgress: [String: Double] = [:]
    var downloadingModelId: String?
    var selectedModelPath: String? {
        didSet {
            UserDefaults.standard.set(selectedModelPath, forKey: "selectedModelPath")
        }
    }

    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("io.monawwar.wave/models")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    init() {
        selectedModelPath = UserDefaults.standard.string(forKey: "selectedModelPath")
    }

    func fileURL(for model: WhisperModel) -> URL {
        Self.modelsDirectory.appendingPathComponent(model.filename)
    }

    func isDownloaded(_ model: WhisperModel) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: model).path)
    }

    func download(_ model: WhisperModel) {
        guard let url = URL(string: model.url) else { return }
        downloadingModelId = model.id.uuidString

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.downloadingModelId = nil
                self.downloadProgress.removeValue(forKey: model.id.uuidString)

                if let error = error {
                    print("Download error: \(error.localizedDescription)")
                    return
                }

                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                      let tempURL = tempURL else {
                    print("Download failed: bad response")
                    return
                }

                do {
                    let dest = self.fileURL(for: model)
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                } catch {
                    print("File move error: \(error.localizedDescription)")
                }
            }
        }

        observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress[model.id.uuidString] = progress.fractionCompleted
            }
        }

        downloadTask = task
        task.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadingModelId = nil
        downloadProgress.removeAll()
        observation = nil
    }

    func selectModel(_ model: WhisperModel) {
        selectedModelPath = fileURL(for: model).path
    }

    func selectModelAtPath(_ path: String) {
        selectedModelPath = path
    }

    func deleteModel(_ model: WhisperModel) {
        let url = fileURL(for: model)
        try? FileManager.default.removeItem(at: url)
        if selectedModelPath == url.path {
            selectedModelPath = nil
        }
    }
}
