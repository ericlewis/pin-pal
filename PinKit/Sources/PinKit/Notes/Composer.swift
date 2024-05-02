import SwiftUI

struct Composer: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(HumaneCenterService.self)
    private var service

    @State
    private var title = ""
    
    @State
    private var text = ""
    
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
                    Button("Save", action: save)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                }
            }
            .navigationTitle(editorTitle)
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
            do {
                if let uuid = editableNote.uuid, let memoryUuid = editableNote.memoryUuid {
                    editableNote.title = title
                    editableNote.text = text
                    try await service.update(memoryUuid.uuidString, .init(text: text, title: title))
                } else {
                    let result = try await service.create(.init(text: text, title: title))
                    editableNote.update(using: result.get()!, isFavorited: false, createdAt: .now)
                    modelContext.insert(editableNote)
                    try modelContext.save()
                }
                dismiss()
            } catch {
                self.errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

