import AVFoundation
import Combine

enum AudioManagerError: Error {
    case microphonePermissionDenied
    case audioSessionSetupFailed(Error)
    case recordingStartFailed(Error)
    case noActiveRecording
}

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var playingNote: AudioNote?
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    @Published var currentTime: TimeInterval = 0

    private func requestMicrophonePermission() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AudioManagerError.microphonePermissionDenied)
                }
            }
        }
    }

    func prepareToRecord() async throws {
        try await requestMicrophonePermission()
        try record()
    }

    private func record() throws {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            throw AudioManagerError.audioSessionSetupFailed(error)
        }

        let audioFilename = FileManager.default.documentsDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.startTimer()
            }
        } catch {
            throw AudioManagerError.recordingStartFailed(error)
        }
    }

    func stopRecording() throws -> String {
        guard let recorder = audioRecorder, recorder.isRecording else {
            throw AudioManagerError.noActiveRecording
        }

        recorder.stop()

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopTimer()
        }

        return recorder.url.lastPathComponent
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            self.currentTime = recorder.currentTime
        }

    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentTime = 0
    }
}

extension AudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }
}
