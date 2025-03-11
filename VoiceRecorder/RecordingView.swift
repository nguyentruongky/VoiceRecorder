import SwiftUI

struct RecordingView: View {
    @ObservedObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    
    
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
                        if let fileName = audioManager.stopRecording() {
                            let note = AudioNote(
//                                title: title.isEmpty ? "Note \(Date().timeIntervalSince1970)" : title,
                                title: fileName,
                                duration: audioManager.currentTime
                            )
                            modelContext.insert(note)
                            try? modelContext.save()
                            dismiss()
                        }
                    } else {
                        audioManager.startRecording()
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
                        _ = audioManager.stopRecording()
                    }
                    dismiss()
                }
            }
        }
    }
    
    func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        let milliseconds = Int((timeInSeconds.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
