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
