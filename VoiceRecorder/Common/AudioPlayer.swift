import AVFoundation
import Foundation
import SwiftUI

enum AudioPlayerError: Error {
    case invalidURL
    case playbackError(Error)
    case audioSessionError(Error)
    case playerNotInitialized
}

class AudioPlayer: NSObject {
    static let shared = AudioPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var currentViewModel: AudioNoteViewModel?
    private var progressUpdateTimer: Timer?

    @Published var currentTime: TimeInterval = 0

    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }

    deinit {
        cleanUp()
    }

    func play(viewModel: AudioNoteViewModel) throws {
        if let currentVM = currentViewModel, currentVM !== viewModel {
            currentVM.setPlaying(false)
        }

        cleanUp()

        guard let url = viewModel.url else {
            throw AudioPlayerError.invalidURL
        }

        do {
            try configureAudioSession()

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else {
                throw AudioPlayerError.playerNotInitialized
            }

            player.delegate = self
            player.prepareToPlay()

            if player.play() {
                currentViewModel = viewModel
                viewModel.setPlaying(true)
                startProgressTimer()
            } else {
                throw AudioPlayerError.playbackError(NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"]))
            }
        } catch let playbackError {
            throw AudioPlayerError.playbackError(playbackError)
        }
    }

    func stop() {
        audioPlayer?.stop()
        cleanUp()
    }

    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }

        player.pause()
        stopProgressTimer()
        currentViewModel?.setPlaying(false)
    }

    func resume() throws {
        guard let player = audioPlayer else {
            throw AudioPlayerError.playerNotInitialized
        }

        if player.play() {
            startProgressTimer()
            currentViewModel?.setPlaying(true)
        } else {
            throw AudioPlayerError.playbackError(NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to resume playback"]))
        }
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }

        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
    }

    private func configureAudioSession() throws {
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
    }

    private func startProgressTimer() {
        stopProgressTimer()

        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.audioPlayer else { return }
            currentTime = player.currentTime
        }

        RunLoop.current.add(progressUpdateTimer!, forMode: .common)
    }

    private func stopProgressTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }

    private func cleanUp() {
        audioPlayer?.stop()
        audioPlayer = nil

        stopProgressTimer()

        if let viewModel = currentViewModel {
            viewModel.setPlaying(false)
        }

        currentViewModel = nil
        currentTime = 0

        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.currentViewModel?.setPlaying(false)
            self.currentViewModel = nil
            self.audioPlayer = nil
            self.stopProgressTimer()
            self.currentTime = 0

            try? self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio player decode error: \(error.localizedDescription)")
        }
        cleanUp()
    }
}
