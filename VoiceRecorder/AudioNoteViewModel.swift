import Foundation
import AVFoundation

class AudioNoteViewModel: ObservableObject {
    let note: AudioNote
    var url: URL? {
        getFileURLFromDocumentsDirectory(fileName: note.title)
    }
    @Published private(set) var isPlaying: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

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
        do {
            try playerManager.play(viewModel: self)
        } catch AudioPlayerError.invalidURL {
            // Show alert for invalid URL
            displayAlert(message: "Cannot play audio: Invalid URL")
        } catch AudioPlayerError.playbackError(let error) {
            // Show alert for playback error
            displayAlert(message: "Cannot play audio: \(error.localizedDescription)")
        } catch {
            // Show alert for any other error
            displayAlert(message: "An unexpected error occurred")
        }
    }

    private func displayAlert(message: String) {
        alertMessage = message
        showAlert = true
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
