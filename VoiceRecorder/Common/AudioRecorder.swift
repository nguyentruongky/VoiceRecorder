import AVFoundation
import Combine

enum AudioManagerError: Error {
    case microphonePermissionDenied
    case audioSessionSetupFailed(Error)
    case recordingStartFailed(Error)
    case noActiveRecording
    case recordingFailed
}

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }

    deinit {
        cleanUp()
    }

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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
        } catch {
            throw AudioManagerError.audioSessionSetupFailed(error)
        }

        let audioFilename = FileManager.default.documentsDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self

            if audioRecorder?.record() == false {
                throw AudioManagerError.recordingFailed
            }

            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.startTimer()
            }
        } catch {
            try? audioSession.setActive(false)
            throw AudioManagerError.recordingStartFailed(error)
        }
    }

    func stopRecording() throws -> String {
        guard let recorder = audioRecorder, recorder.isRecording else {
            throw AudioManagerError.noActiveRecording
        }

        let url = recorder.url
        recorder.stop()

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopTimer()
        }

        try? audioSession.setActive(false)

        return url.lastPathComponent
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }

            self.currentTime = recorder.currentTime
        }

        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentTime = 0
    }

    func cleanUp() {
        if isRecording {
            audioRecorder?.stop()
        }

        stopTimer()
        audioRecorder = nil

        try? audioSession.setActive(false)
    }

    var currentRecordingURL: URL? {
        return audioRecorder?.url
    }
}

extension AudioRecorder: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.cleanUp()
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.cleanUp()
        }
    }
}
