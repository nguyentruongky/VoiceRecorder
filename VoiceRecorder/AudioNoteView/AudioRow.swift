import SwiftUI

struct AudioNoteRow: View {
    @StateObject private var viewModel: AudioNoteViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(note: AudioNote) {
        _viewModel = StateObject(wrappedValue: AudioNoteViewModel(note: note))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(viewModel.isPlaying ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.isPlaying ? .red : .gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    viewModel.startEditing()
                }) {
                    Text(viewModel.note.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle())

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    Text(viewModel.note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    Text(viewModel.currentTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                viewModel.togglePlayback()
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isPlaying ? Color.red : Color.blue)
                        .frame(width: 44, height: 44)

                    Image(systemName: viewModel.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            EditTitleView(title: viewModel.note.title) { newTitle in
                viewModel.updateTitle(newTitle)
            }
        }
        .listRowSeparator(.hidden)
    }
}
