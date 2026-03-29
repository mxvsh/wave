import Foundation
import AVFoundation

actor AudioRecorder {
    private var recorder: AVAudioRecorder?

    enum RecorderError: Error {
        case couldNotStartRecording
    }

    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) throws {
        let recordSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: recordSettings)
        recorder.delegate = delegate
        recorder.isMeteringEnabled = true
        if recorder.record() == false {
            throw RecorderError.couldNotStartRecording
        }
        self.recorder = recorder
    }

    func currentLevel() -> Float {
        guard let recorder else { return 0 }
        recorder.updateMeters()
        // averagePower is in dB: -160 (silence) to 0 (max)
        let db = recorder.averagePower(forChannel: 0)
        let minDb: Float = -50
        guard db > minDb else { return 0 }
        return 1.0 - (db / minDb) // normalize to 0–1
    }

    func stopRecording() {
        recorder?.stop()
        recorder = nil
    }
}
