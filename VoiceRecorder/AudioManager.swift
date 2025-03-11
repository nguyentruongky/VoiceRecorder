import AVFoundation
import Combine

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var playingNote: AudioNote?
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    @Published var currentTime: TimeInterval = 0
    
    override init() {
        super.init()
        
        requestMicrophonePermission()
    }
    
    private func requestMicrophonePermission() {
            AVAudioSession.sharedInstance().requestRecordPermission { response in
                if !response {
                    print("Microphone permission denied")
                }
            }
        }
    
    func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
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
            isRecording = true
            
            startTimer()
        } catch {
            print("Could not start recording")
        }
    }
    
    func stopRecording() -> String? {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        return audioRecorder?.url.lastPathComponent
    }
    

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.currentTime = self?.audioRecorder?.currentTime ?? 0
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
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    }
}
