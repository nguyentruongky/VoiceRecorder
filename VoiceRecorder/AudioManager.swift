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
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // AAC format
            AVSampleRateKey: 12000,                   // 12 kHz sample rate (adjust if needed)
            AVNumberOfChannelsKey: 1,                 // Mono channel
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue // High quality
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
        // Make sure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.startTimer()
            }
            return
        }

        // Stop any existing timer first
        stopTimer()

        // Create a new timer on the main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            self.currentTime = recorder.currentTime
        }

        // Make sure the timer is added to the current run loop
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        // Make sure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stopTimer()
            }
            return
        }

        timer?.invalidate()
        timer = nil
        currentTime = 0
    }
}

extension AudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    }
}
