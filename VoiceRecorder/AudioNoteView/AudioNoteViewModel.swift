import Foundation
import AVFoundation
import Combine
import SwiftUI

class AudioNoteViewModel: ObservableObject {
    @Environment(\.modelContext) private var modelContext

    let note: AudioNote
    private let fileManager = FileManager.default
    private let player: AudioPlayer
    private var progressSubscription: AnyCancellable?

    var url: URL? {
        getFileURLFromDocumentsDirectory(fileName: note.title)
    }

    var duration: String {
        formatDuration(note.duration)
    }

    var iconName: String {
        isPlaying ? "stop.circle.fill" : "play.circle.fill"
    }

    @Published private(set) var isPlaying: Bool = false
    @Published var currentTime: String = "00:00"
    @Published var progressValue: Float = 0.0
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isEditing: Bool = false
    @Published var fileExists: Bool = false

    init(note: AudioNote, player: AudioPlayer = AudioPlayer.shared) {
        self.note = note
        self.player = player

        checkFileExists()
        setupProgressSubscription()

        currentTime = duration
    }

    private func setupProgressSubscription() {
        progressSubscription = player.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self, self.isPlaying else { return }

                let remainingTime = max(0, self.note.duration - time)
                self.currentTime = self.formatDuration(remainingTime)

                if self.note.duration > 0 {
                    self.progressValue = Float(time / self.note.duration)
                }
            }
    }

    func togglePlayback() {
        if !fileExists {
            displayAlert(message: "Audio file not found. It may have been deleted or moved.")
            return
        }

        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func setPlaying(_ playing: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = playing

            if !playing {
                self.currentTime = self.formatDuration(self.note.duration)
                self.progressValue = 0.0
            }
        }
    }

    func stopPlayback() {
        player.stop()
    }

    func updateTitle(_ newTitle: String) {
        if newTitle.isEmpty || newTitle == note.title {
            return
        }

        guard let oldURL = url else {
            displayAlert(message: "Could not locate the audio file")
            return
        }

        let documentsDirectory = fileManager.documentsDirectory
        let newURL = documentsDirectory.appendingPathComponent(newTitle)

        if fileManager.fileExists(atPath: newURL.path) && oldURL.path != newURL.path {
            displayAlert(message: "A file with this name already exists")
            return
        }

        do {
            if isPlaying {
                stopPlayback()
            }

            try fileManager.moveItem(at: oldURL, to: newURL)

            note.title = newTitle

            try modelContext.save()

            checkFileExists()
        } catch {
            displayAlert(message: "Failed to update title: \(error.localizedDescription)")
        }
    }

    private func startPlayback() {
        do {
            try player.play(viewModel: self)
        } catch AudioPlayerError.invalidURL {
            displayAlert(message: "Cannot play audio: Invalid URL")
        } catch AudioPlayerError.playbackError(let error) {
            displayAlert(message: "Cannot play audio: \(error.localizedDescription)")
        } catch {
            displayAlert(message: "An unexpected error occurred")
        }
    }

    private func displayAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.alertMessage = message
            self?.showAlert = true
        }
    }

    private func getFileURLFromDocumentsDirectory(fileName: String) -> URL? {
        let fileURL = fileManager.documentsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    private func formatDuration(_ timeInSeconds: TimeInterval) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }

    private func checkFileExists() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let exists = self.url != nil

            DispatchQueue.main.async {
                self.fileExists = exists
            }
        }
    }

    func startEditing() {
        isEditing = true
    }
}
