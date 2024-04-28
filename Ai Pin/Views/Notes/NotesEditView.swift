import SwiftUI
import OSLog

struct NotesEditView: View {
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.dismiss) 
    private var dismiss
    
    @State private var triggerSaveHatic = false
    @State var noteId: String
    @State var note: Note
    @State var isLoading = false

    
    @FocusState private var focused
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $note.title)
                TextEditor(text: $note.text)
                    .submitLabel(.done)
            }
            .onAppear {
                focused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                isLoading = true
                                triggerSaveHatic.toggle()
                                
                                let intent = EditNoteIntent(id: noteId, title: note.title, text: note.text)
                                intent.navigationStore = navigationStore
                                do {
                                    let _ = try await intent.perform()
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Note")
        }
        .disabled(isLoading)
        .interactiveDismissDisabled(isLoading)
        .sensoryFeedback(.success, trigger: triggerSaveHatic)
    }
}

#Preview {
    NotesEditView(noteId: "", note: Note(text: "- 'When Doves Cry' by Prince\n- 'Even Flow' by Pearl Jam", title: "Liked Songs"))
}
