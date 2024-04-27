import SwiftUI

struct AddNoteView: View {
    
    struct ViewState {
        var title = ""
        var text = ""
        var isLoading = false
    }
    
    @State
    private var state = ViewState()
    
    @Environment(\.dismiss)
    private var dismiss
    
    @FocusState
    private var focused
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $state.title)
                    .focused($focused)
                TextField("Text", text: $state.text)
                    .submitLabel(.done)
                    .onSubmit {
                        if !state.isLoading {
                            create()
                        }
                    }
            }
            .onAppear {
                focused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if state.isLoading {
                        ProgressView()
                    } else {
                        Button("Add") {
                            create()
                        }
                        .disabled(state.title.isEmpty || state.text.isEmpty)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Note")
        }
        .disabled(state.isLoading)
        .interactiveDismissDisabled(state.isLoading)
    }
    
    func create() {
        Task {
            state.isLoading = true
            let _ = try await API.shared.create(note: .init(text: state.text, title: state.title))
            dismiss()
        }
    }
}

#Preview {
    AddNoteView()
}
