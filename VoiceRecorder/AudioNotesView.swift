import SwiftUI
import SwiftData

struct AudioNotesView: View {
    @Query private var audioNotes: [AudioNote]
        @Environment(\.modelContext) private var modelContext
    @StateObject private var audioManager = AudioManager()
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
                RecordingView(audioManager: audioManager)
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
                Text(viewModel.note.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
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
    }
}
