import Foundation
import AVFoundation

class AudioNoteViewModel: ObservableObject {
    let note: AudioNote
    var url: URL? {
        getFileURLFromDocumentsDirectory(fileName: note.title)
    }
    @Published private(set) var isPlaying: Bool = false
    private let playerManager = AudioPlayerManager.shared
    
    init(note: AudioNote) {
        self.note = note
    }
    
    var iconName: String {
        isPlaying ? "stop.circle.fill" : "play.circle.fill"
    }
    
    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
    }
    
    private func startPlayback() {
        playerManager.play(viewModel: self)
    }
    
    func stopPlayback() {
        playerManager.stop()
    }
    
    
    func getFileURLFromDocumentsDirectory(fileName: String) -> URL? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL!.path) {
            return fileURL
        } else {
            print("File not found in documents directory.")
            return nil
        }
    }
}

