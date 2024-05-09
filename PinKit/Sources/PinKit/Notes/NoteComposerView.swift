import SwiftUI

public struct NoteComposerView: View {
    
    enum Field: Hashable {
        case title
        case text
    }

    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(NavigationStore.self)
    private var navigation

    @FocusState
    private var focus: Field?
    
    @State
    private var title = ""
    
    @State
    private var text = ""
    
    let note: Note?
    
    public init(note: Note?) {
        self.note = note
    }
    
    var isEditing: Bool {
        note != nil
    }
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    
    public var body: some View {
        NavigationStack {
            Form {
                TextField("Note Title", text: $title)
                    .font(.headline)
                    .submitLabel(.next)
                    .focused($focus, equals: .title)
                    .onSubmit {
                        self.focus = .text
                    }
                if horizontalSizeClass == .regular, verticalSizeClass == .regular {
                    TextEditor(text: $text)
                        .focused($focus, equals: .text)
                        .submitLabel(.return)
                        .padding(.bottom, -5)
                        .padding(.leading, -5)
                } else {
                    TextField("Note Text", text: $text, axis: .vertical)
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
                        if navigation.savingNote {
                            ProgressView()
                        } else if let id = note?.memoryId {
                            Button("Save", intent: UpdateNoteIntent(identifier: id.uuidString, title: title, text: text))
                        } else {
                            Button("Save", intent: CreateNoteIntent(title: title, text: text))
                        }
                    }
                    .disabled(title.isEmpty || text.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle(isEditing ? "Update Note" : "New Note")
        }
        .disabled(navigation.savingNote)
        .interactiveDismissDisabled(navigation.savingNote)
        .onAppear {
            self.title = note?.title ?? ""
            self.text = note?.text ?? ""
        }
    }
}

#Preview {
    NoteComposerView(note: .init(text: "", title: ""))
        .environment(HumaneCenterService.live())
}
