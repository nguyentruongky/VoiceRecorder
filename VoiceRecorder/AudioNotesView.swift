import SwiftUI
import SwiftData

struct AudioNotesView: View {
    @Query private var audioNotes: [AudioNote]
        @Environment(\.modelContext) private var modelContext
    @State private var showingRecordingSheet = false

    var body: some View {
        NavigationView {
            List(audioNotes) { note in
                AudioNoteRow(note: note)
            }
            .navigationTitle("Audio Notes")
            .toolbar {
                Button(action: { showingRecordingSheet = true }) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title)
                }
            }
            .sheet(isPresented: $showingRecordingSheet) {
                RecordingView()
            }
        }
    }
}

struct AudioNoteRow: View {
    @StateObject private var viewModel: AudioNoteViewModel

    init(note: AudioNote) {
        _viewModel = StateObject(wrappedValue: AudioNoteViewModel(note: note))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.note.title)
                    .font(.headline)
                HStack {
                    Text(viewModel.note.createdAt.formatted())
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(formatDuration(viewModel.note.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button(action: {
                viewModel.togglePlayback()
            }) {
                Image(systemName: viewModel.iconName)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // Helper function to format duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }
}
