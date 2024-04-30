import SwiftUI

public struct NoteComposerView: View {
    
    enum Field: Hashable {
        case title
        case text
    }
    
    struct ViewState {
        var isLoading = false
    }
    
    @State
    private var state = ViewState()
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(NotesRepository.self)
    private var notesRepository
    
    @FocusState
    private var focus: Field?
    
    @Bindable
    var note: Note
    
    public init(note: Note) {
        self.note = note
    }
    
    var isEditing: Bool {
        note.uuid != nil
    }
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    
    public var body: some View {
        NavigationStack {
            Form {
                TextField("Note Title", text: $note.title)
                    .font(.headline)
                    .submitLabel(.next)
                    .focused($focus, equals: .title)
                    .onSubmit {
                        self.focus = .text
                    }
                if horizontalSizeClass == .regular, verticalSizeClass == .regular {
                    TextEditor(text: $note.text)
                        .focused($focus, equals: .text)
                        .submitLabel(.return)
                        .padding(.bottom, -5)
                        .padding(.leading, -5)
                } else {
                    TextField("Note Text", text: $note.text, axis: .vertical)
                        .focused($focus, equals: .text)
                        .submitLabel(.return)
                }
            }
            .onAppear {
                if !isEditing {
                    self.focus = .title
                } else {
                    self.focus = .text
                }
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
                    intent.notesRepository = notesRepository
                    let _ = try await intent.perform()
                } else {
                    let intent = CreateNoteIntent(title: note.title, text: note.text)
                    intent.navigationStore = navigationStore
                    intent.notesRepository = notesRepository
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
        .environment(HumaneCenterService.live())
}
