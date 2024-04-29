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
    
    @Environment(HumaneCenterService.self)
    private var api
    
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
                TextField("Note Text", text: $note.text, axis: .vertical)
                    .focused($focus, equals: .text)
                    .submitLabel(.return)
                    .onSubmit {
                        if !state.isLoading, !note.title.isEmpty, !note.text.isEmpty {
                            save()
                        }
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
                    intent.api = api
                    let _ = try await intent.perform()
                } else {
                    let intent = CreateNoteIntent(title: note.title, text: note.text)
                    intent.navigationStore = navigationStore
                    intent.api = api
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
