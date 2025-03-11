import SwiftUI

struct RecordingView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Note Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Text(formatTime(audioManager.currentTime))
                    .font(.largeTitle)
                    .monospacedDigit()

                Button(action: {
                    if audioManager.isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    Image(systemName: audioManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(audioManager.isRecording ? .red : .blue)
                }
            }
            .navigationTitle("New Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Cancel") {
                    if audioManager.isRecording {
                        do {
                            _ = try audioManager.stopRecording()
                        } catch {
                            // Just log the error when canceling
                            print("Error stopping recording during cancel: \(error)")
                        }
                    }
                    dismiss()
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private func startRecording() {
        Task {
            do {
                try await audioManager.prepareToRecord()
            } catch AudioManagerError.microphonePermissionDenied {
                showErrorAlert("Microphone access is required for recording. Please enable it in Settings.")
            } catch AudioManagerError.audioSessionSetupFailed(let error) {
                showErrorAlert("Failed to set up audio session: \(error.localizedDescription)")
            } catch AudioManagerError.recordingStartFailed(let error) {
                showErrorAlert("Failed to start recording: \(error.localizedDescription)")
            } catch {
                showErrorAlert("An unexpected error occurred: \(error.localizedDescription)")
            }
        }
    }

    private func stopRecording() {
        do {
            let fileName = try audioManager.stopRecording()
            let note = AudioNote(
                title: fileName,
                duration: audioManager.currentTime
            )
            modelContext.insert(note)
            try? modelContext.save()
            dismiss()
        } catch AudioManagerError.noActiveRecording {
            showErrorAlert("No active recording to stop.")
        } catch {
            showErrorAlert("Failed to stop recording: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func showErrorAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        let milliseconds = Int((timeInSeconds.truncatingRemainder(dividingBy: 1)) * 100)

        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
