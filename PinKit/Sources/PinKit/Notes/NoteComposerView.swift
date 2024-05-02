import SwiftUI

struct NoteComposerView: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore

    @State
    private var title = ""
    
    @State
    private var text = ""
    
    @State
    private var isLoading = false
    
    @State
    private var showErrorAlert: Bool = false
    
    @State
    private var errorMessage: String?

    @FocusState
    private var focus: Focusables?

    var editableNote: _Note

    enum Focusables {
        case title
        case text
    }

    private var editorTitle: LocalizedStringKey {
        editableNote.uuid == nil ? "Add Note" : "Edit Note"
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                    .submitLabel(.next)
                    .focused($focus, equals: .title)
                    .onSubmit { focus = .text }
                TextField("Text", text: $text, axis: .vertical)
                    .submitLabel(.return)
                    .focused($focus, equals: .text)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save", action: save)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                }
            }
            .navigationTitle(editorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isLoading)
            .interactiveDismissDisabled(isLoading)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "No")
        }
        .onAppear(perform: setup)
    }
    
    private func setup() {
        title = editableNote.title
        text = editableNote.text
        focus = title.isEmpty ? .title : .text
    }

    private func save() {
        Task {
            isLoading = true
            do {
                if let memoryUuid = editableNote.memoryUuid {
                    let intent = UpdateNoteIntent(identifier: memoryUuid.uuidString, title: title, text: text)
                    intent.navigationStore = navigationStore
                    intent.database = database
                    intent.service = service
                    let _ = try await intent.perform()
                } else {
                    let intent = CreateNoteIntent(title: title, text: text)
                    intent.navigationStore = navigationStore
                    intent.database = database
                    intent.service = service
                    let _ = try await intent.perform()
                }
                dismiss()
            } catch {
                self.errorMessage = error.localizedDescription
                showErrorAlert = true
            }
            isLoading = false
        }
    }
}

