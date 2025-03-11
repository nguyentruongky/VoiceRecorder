import SwiftUI

struct EditTitleView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool
    @State private var title: String
    private var onSave: (String) -> Void

    init(title: String, onSave: @escaping (String) -> Void) {
        self._title = State(initialValue: title)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recording Title")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Enter title", text: $title)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isTitleFocused)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .navigationTitle("Edit Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !title.isEmpty {
                            onSave(title)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTitleFocused = true
                }
            }
        }
    }
}
