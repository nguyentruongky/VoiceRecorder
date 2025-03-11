import Foundation
import AVFoundation
import SwiftUI

class AudioNoteViewModel: ObservableObject {
    @Environment(\.modelContext) private var modelContext

    let note: AudioNote
    var url: URL? {
        getFileURLFromDocumentsDirectory(fileName: note.title)
    }

    var duration: String {
        let duration = note.duration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }

    @Published private(set) var isPlaying: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isEditing: Bool = false
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
            displayAlert(message: "Cannot play audio: Invalid URL")
        } catch AudioPlayerError.playbackError(let error) {
            displayAlert(message: "Cannot play audio: \(error.localizedDescription)")
        } catch {
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
        let documentsDirectory = fileManager.documentsDirectory

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            print("File not found in documents directory.")
            return nil
        }
    }

    func startEditing() {
        isEditing = true
    }

    func updateTitle(_ newTitle: String) {
        guard let oldURL = url else {
            alertMessage = "Could not locate the audio file"
            showAlert = true
            return
        }

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newURL = documentsDirectory.appendingPathComponent(newTitle)

        do {
            try fileManager.moveItem(at: oldURL, to: newURL)

            note.title = newTitle

            try modelContext.save()
        } catch {
            alertMessage = "Failed to update title: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
