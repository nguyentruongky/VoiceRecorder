import SwiftUI

struct RecordingView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 280, height: 280)

                        Circle()
                            .strokeBorder(audioManager.isRecording ? Color.red : Color.blue, lineWidth: 4)
                            .frame(width: 240, height: 240)

                        VStack(spacing: 8) {
                            Text("Recording Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(formatTime(audioManager.currentTime))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(audioManager.isRecording ? .red : .primary)
                        }
                    }
                    .padding(.top, 40)

                    Spacer()

                    VStack(spacing: 24) {
                        Button(action: {
                            if audioManager.isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(audioManager.isRecording ? Color.red : Color.blue)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                                Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(audioManager.isRecording ? "Tap to stop recording" : "Tap to start recording")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 60)
                }
                .padding()
            }
            .navigationTitle("New Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if audioManager.isRecording {
                            do {
                                _ = try audioManager.stopRecording()
                            } catch {
                                print("Error stopping recording during cancel: \(error)")
                            }
                        }
                        dismiss()
                    }
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
