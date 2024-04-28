import SwiftUI

struct NoteComposerView: View {
    
    struct ViewState {
        var isLoading = false
    }
    
    @State
    private var state = ViewState()
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @FocusState
    private var focused
    
    @Bindable
    var note: Note
    
    var isEditing: Bool {
        note.uuid != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $note.title)
                    .focused($focused)
                TextField("Text", text: $note.text, axis: .vertical)
                    .submitLabel(.done)
                    .onSubmit {
                        if !state.isLoading, !note.title.isEmpty, !note.text.isEmpty {
                            save()
                        }
                    }
            }
            .onAppear {
                focused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Group {
                        if state.isLoading {
                            ProgressView()
                        } else {
                            Button("Save") {
                                save()
                            }
                        }
                    }
                    .disabled(note.title.isEmpty || note.text.isEmpty)

                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle(isEditing ? "Update Note" : "New Note")
        }
        .disabled(state.isLoading)
        .interactiveDismissDisabled(state.isLoading)
    }
    
    func save() {
        Task {
            do {
                state.isLoading = true
                if let uuid = note.memoryId {
                    let intent = UpdateNoteIntent(identifier: uuid.uuidString, title: note.title, text: note.text)
                    intent.navigationStore = navigationStore
                    let _ = try await intent.perform()
                } else {
                    let intent = CreateNoteIntent(title: note.title, text: note.text)
                    intent.navigationStore = navigationStore
                    let _ = try await intent.perform()
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    NoteComposerView(note: .init(text: "", title: ""))
}
