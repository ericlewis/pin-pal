import SwiftUI
import SwiftData

extension _Note {
    static let filter = #Predicate<_Note> {
        $0.uuid != nil
    }
}

struct Comp: View {
    
    var editableNote: _Note

    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @State
    private var title = ""
    
    @State
    private var text = ""
    
    private var editorTitle: LocalizedStringKey {
        editableNote.uuid == nil ? "Add Note" : "Edit Note"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Text", text: $text)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let memoryId = editableNote.memoryUuid, let id = editableNote.uuid {
                                editableNote.text = text
                                editableNote.title = title
                                try await service.update(memoryId.uuidString, .init(
                                    uuid: id,
                                    text: text,
                                    title: title
                                ))
                            } else {
//                                let result = try await service.create(.init(text: editableNote.text, title: editableNote.title))
//                                editableNote.update(using: result.get()!, isFavorited: false, createdAt: .now)
//                                self.modelContext.insert(editableNote)
//                                try self.modelContext.save()
                            }
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            title = editableNote.title
            text = editableNote.text
        }
    }
}

public struct ContentView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(\.modelContext)
    private var context
    
    @State
    private var noteToEdit: _Note?
    
    @Query(filter: _Note.filter, sort: [SortDescriptor(\_Note.createdAt, order: .reverse)])
    private var notes: [_Note]

    public init() {}
    
    public var body: some View {
        @Bindable
        var navigationStore = navigationStore
        
//        TabView(selection: $navigationStore.selectedTab) {
//            DashboardView()
//                .tabItem {
//                    Label("Memories", systemImage: "memories")
//                }
//                .tag(Tab.dashboard)
//            NotesView()
//                .tabItem {
//                    Label("Notes", systemImage: "note.text")
//                }
//                .tag(Tab.notes)
//            CapturesView()
//                .tabItem {
//                    Label("Captures", systemImage: "camera.aperture")
//                }
//                .tag(Tab.captures)
//            MyDataView()
//                .tabItem {
//                    Label("My Data", systemImage: "person.text.rectangle")
//                }
//                .tag(Tab.myData)
//            SettingsView()
//                .tabItem {
//                    Label("Settings", systemImage: "gear")
//                }
//                .tag(Tab.settings)
//        }
        NavigationStack {
            List {
                ForEach(notes) { note in
                    Button {
                        self.noteToEdit = note
                    } label: {
                        LabeledContent {} label: {
                            Text(note.title)
                            Text(note.text)
                        }
                        .task {
                            guard let id = note.memoryUuid else { return }
                            do {
                                let _ = try await service.memory(id)
                            } catch {
                                context.delete(note)
                                try? context.save()
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            do {
                                let note = notes[index]
                                let id = note.uuid
                                guard let uuid = note.memoryUuid else {
                                    return
                                }
                                try await context.delete(note)
                                try await service.deleteByNoteId(uuid)
                                try await context.save()
                                print("saved!")
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
            .refreshable(action: load)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Create note", systemImage: "plus") {
                        self.noteToEdit = _Note(from: .init(text: "", title: ""), isFavorited: false, createdAt: .now)
                    }
                }
            }
        }
        .sheet(item: $noteToEdit) { note in
            Comp(editableNote: note)
        }
        .modifier(AuthHandlerViewModifier())
        .environment(navigationStore)
        .task(load)
    }
    
    func load() async {
        do {
            let response = try await service.notes(0, 10)
            let responses = try await (0..<response.totalPages).asyncCompactMap { pageNumber in
                try? await service.notes(pageNumber, 10).content
            }
            let content: [ContentEnvelope] = responses.flatMap({ $0 })
            await withThrowingTaskGroup(of: Void.self) { group in
                for item in content {
                    group.addTask {
                        guard var note: Note = item.get() else { return }
                        note.memoryId = item.uuid
                        var fetch = FetchDescriptor<_Note>()
                        fetch.fetchLimit = 1
                        fetch.predicate = #Predicate {
                            $0.uuid == note.uuid
                        }
                        if let res = await try database.fetch(fetch).first {
                            res.update(using: note, isFavorited: item.favorite, createdAt: item.userCreatedAt)
                        } else {
                            await database.insert(_Note(from: note, isFavorited: item.favorite, createdAt: item.userCreatedAt))
                        }
                    }
                }
            }
            try Task.checkCancellation()
            try await database.save()
        } catch {
            print(error)
        }
    }
}

#Preview {
    ContentView()
}
