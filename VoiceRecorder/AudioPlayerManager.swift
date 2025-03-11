import AVFoundation
import Foundation
import SwiftUI

enum AudioPlayerError: Error {
    case invalidURL
    case playbackError(Error)
}

class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()
    private var audioPlayer: AVAudioPlayer?
    private var currentViewModel: AudioNoteViewModel?

    private override init() {
        super.init()
    }

    func play(viewModel: AudioNoteViewModel) throws {
        if let currentVM = currentViewModel, currentVM !== viewModel {
            currentVM.stopPlayback()
        }

        guard let url = viewModel.url else {
            throw AudioPlayerError.invalidURL
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            currentViewModel = viewModel
            viewModel.setPlaying(true)
        } catch {
            print("Could not start playing: \(error)")
            throw AudioPlayerError.playbackError(error)
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentViewModel?.setPlaying(false)
        currentViewModel = nil
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.currentViewModel?.setPlaying(false)
            self.currentViewModel = nil
            self.audioPlayer = nil
        }
    }
}
