import AppIntents
import PinKit
import SwiftUI
import Models

public struct NoteEntity: Identifiable {
    
    public let id: UUID
    
    @Property(title: "Name")
    public var title: String
    
    @Property(title: "Body")
    public var text: String
    
    @Property(title: "Creation Date")
    public var createdAt: Date
    
    @Property(title: "Last Modified Date")
    public var modifiedAt: Date

    public init(from content: MemoryContentEnvelope) {
        let note: NoteEnvelope = content.get()!
        self.id = note.memoryId!
        self.createdAt = note.createdAt!
        self.modifiedAt = note.modifiedAt!
        self.title = note.title
        self.text = note.text
    }
    
    public init(from note: Note) {
        self.id = note.parentUUID
        self.createdAt = note.createdAt
        self.modifiedAt = note.modifiedAt
        self.title = note.name
        self.text = note.body
    }
}

extension NoteEntity: AppEntity {
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(text)")
    }
    
    public static var defaultQuery: NoteEntityQuery = NoteEntityQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Notes")
}

public struct NoteEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery {
    
    public func allEntities() async throws -> [NoteEntity] {
        try await database.fetch(Note.all())
            .map(NoteEntity.init(from:))
    }
    
    public static var findIntentDescription: IntentDescription? {
        .init("", categoryName: "Notes")
    }
    
    @Dependency
    var service: HumaneCenterService
    
    @Dependency
    var database: any Database
    
    public init() {}
    
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            try? await NoteEntity(from: service.memory(id))
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .notes).memories?.map(\.uuid) ?? [])
    }
  
    public func suggestedEntities() async throws -> [NoteEntity] {
        var descriptor = Note.all()
        descriptor.fetchLimit = 30
        return try await database.fetch(descriptor)
            .map(NoteEntity.init(from:))
    }
}


public struct OpenNoteIntent: OpenIntent {
        
    public static var title: LocalizedStringResource = "Open Note"
    public static var description: IntentDescription? = .init("Opens a specific note in Pin Pal", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @Parameter(title: "Note")
    public var target: NoteEntity

    public init(note: NoteEntity) {
        self.target = note
    }
    
    public init(note: Note) {
        self.target = .init(from: note)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        navigation.activeNote = .init(
            uuid: target.id,
            memoryId: target.id,
            text: target.text,
            title: target.title,
            createdAt: target.createdAt,
            modifedAt: target.modifiedAt
        )
        return .result()
    }
}

public struct CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    public static var description: IntentDescription? = .init("Creates a note using the content passed as input.",
                                                              categoryName: "Notes",
                                                              resultValueName: "New Note"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Create note with \(\.$text) named \(\.$title)")
    }
    
    @Parameter(title: "Name", requestValueDialog: .init("What would you like to name your note?"))
    public var title: String
    
    @Parameter(title: "Body", requestValueDialog: .init("What would you like your note to say?"))
    public var text: String
    
    public init(title: String, text: String) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigation: Navigation

    @Dependency
    public var database: any Database
    
    @Dependency
    public var service: HumaneCenterService
    
    public func perform() async throws -> some IntentResult {
        navigation.savingNote = true
        let content = try await service.create(.init(text: text, title: title))
        let note: NoteEnvelope = content.get()!
        await database.insert(
            Note(
                uuid: note.id ?? .init(),
                parentUUID: content.id,
                name: note.title,
                body: note.text,
                isFavorite: content.favorite,
                createdAt: content.userCreatedAt,
                modifedAt: content.userLastModified
            )
        )
        try await database.save()
        navigation.activeNote = nil
        navigation.savingNote = false
        return .result()
    }
}

public enum FavoriteAction: String, AppEnum {
    case add
    case remove
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Favorite Action")
    public static var caseDisplayRepresentations: [FavoriteAction: DisplayRepresentation] = [
        .add: "Add",
        .remove: "Remove"
    ]
}

public struct FavoriteNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Favorite Notes"
    public static var description: IntentDescription? = .init("Adds or removes notes from the set of favorited notes.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$action) \(\.$notes) to favorites")
    }

    @Parameter(title: "Favorite Action", default: FavoriteAction.add)
    public var action: FavoriteAction
    
    @Parameter(title: "Notes")
    public var notes: [NoteEntity]
    
    public init(action: FavoriteAction, notes: [NoteEntity]) {
        self.action = action
        self.notes = notes
    }
    
    public init(action: FavoriteAction, notes: [Note]) {
        self.action = action
        self.notes = notes.map(NoteEntity.init(from:))
    }
    
    public init(action: FavoriteAction, note: Note) {
        self.init(action: action, notes: [note])
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    var database: any Database

    public func perform() async throws -> some IntentResult {
        let ids = notes.map(\.id)
        if action == .add {
            let _ = try await service.bulkFavorite(ids)
        } else {
            let _ = try await service.bulkUnfavorite(ids)
        }
        await ids.concurrentForEach { id in
            do {
                let content = try await service.memory(id)
                guard let note: NoteEnvelope = content.get() else {
                    return
                }
                await self.database.insert(Note(
                    uuid: note.uuid ?? .init(),
                    parentUUID: content.id,
                    name: note.title,
                    body: note.text,
                    isFavorite: action == .add,
                    createdAt: content.userCreatedAt,
                    modifedAt: content.userLastModified)
                )
            } catch {
                print(error)
            }
        }
        try await self.database.save()
        return .result()
    }
}

public struct AppendToNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Append to Note"
    public static var description: IntentDescription? = .init("Appends the text passed as input to the specified note.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Append \(\.$text) to \(\.$note)")
    }
    
    @Parameter(title: "Note")
    public var note: NoteEntity
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(note: NoteEntity, text: String) {
        self.note = note
        self.text = text
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        let newBody = """
    \(note.text)
    \(text)
    """
        let content = try await service.update(.init(uuid: note.id, text: newBody, title: note.title))
        let note: NoteEnvelope = content.get()!
        await database.insert(
            Note(
                uuid: note.id ?? .init(),
                parentUUID: content.id,
                name: note.title,
                body: note.text,
                isFavorite: content.favorite,
                createdAt: content.userCreatedAt,
                modifedAt: content.userLastModified
            )
        )
        try await database.save()
        return .result(value: .init(from: content))
    }
}

public struct DeleteNotesIntent: DeleteIntent {
    public static var title: LocalizedStringResource = "Delete Notes"
    public static var description: IntentDescription? = .init("Deletes the specified notes.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        When(\.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete \(\.$entities)") {
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete \(\.$entities)") {
                \.$confirmBeforeDeleting
            }
        })
    }
    
    @Parameter(title: "Notes")
    public var entities: [NoteEntity]

    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the notes will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    public init(entities: [NoteEntity], confirmBeforeDeleting: Bool) {
        self.entities = entities
        self.confirmBeforeDeleting = confirmBeforeDeleting
    }
    
    public init(entities: [Note], confirmBeforeDeleting: Bool) {
        self.entities = entities.map(NoteEntity.init(from:))
        self.confirmBeforeDeleting = confirmBeforeDeleting
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult {
        let ids = entities.map(\.id)
        if confirmBeforeDeleting {
            let notesList = entities.map { $0.title }
            let formattedList = notesList.formatted(.list(type: .and, width: .short))
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete \(formattedList)?"))
            let _ = try await service.bulkRemove(ids)
        } else {
            let _ = try await service.bulkRemove(ids)
        }
        
        try await database.delete(where: #Predicate<Note> {
            ids.contains($0.parentUUID)
        })
        try await database.save()
        
        return .result()
    }
}

public struct DeleteAllNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Delete All Notes"
    public static var description: IntentDescription? = .init("Deletes all the notes on this account.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        When(\.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete all Notes") {
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete all Notes") {
                \.$confirmBeforeDeleting
            }
        })
    }
    
    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the notes will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    public init(confirmBeforeDeleting: Bool) {
        self.confirmBeforeDeleting = confirmBeforeDeleting
    }

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    
    // TODO: review if we should expose this... it's kinda dangerous
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult {
        if confirmBeforeDeleting {
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete all Notes? This is not reversible."))
            let _ = try await service.deleteAllNotes()
        } else {
            let _ = try await service.deleteAllNotes()
        }
        
        try await database.delete(where: #Predicate<Note> { _ in true })
        try await database.save()
        
        return .result()
    }
}

public struct _DeleteAllNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Delete All Notes"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    
    // TODO: review if we should expose this... it's kinda dangerous
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        navigation.deleteAllNotesConfirmationPresented = true
        return .result()
    }
}

public struct SearchNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Search Notes"
    public static var description: IntentDescription? = .init("Performs a search for the specified text.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Search \(\.$query) in Notes")
    }
    
    @Parameter(title: "Text")
    public var query: String
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<[NoteEntity]> {
        let results = try await service.search(query, .notes)
        guard let ids = results.memories?.map(\.uuid) else {
            return .result(value: [])
        }
        let memories = await ids.concurrentCompactMap { id in
            try? await service.memory(id)
        }
        return .result(value: memories.map(NoteEntity.init(from:)))
    }
}

public struct ReplaceNoteBodyIntent: AppIntent {
    public static var title: LocalizedStringResource = "Update Note"
    public static var description: IntentDescription? = .init("Replace the body or title of the specified note.", categoryName: "Notes")
    public static var parameterSummary: some ParameterSummary {
        Summary("Update \(\.$body) on \(\.$note)")
    }

    @Parameter(title: "Body")
    public var body: String
    
    @Parameter(title: "Note")
    public var note: NoteEntity
    
    public init(note: NoteEntity) {
        self.note = note
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        try await .result(value: .init(from: service.update(.init(uuid: note.id, text: body, title: note.title))))
    }
}

public struct ShowNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Notes"
    public static var description: IntentDescription? = .init("Get quick access to notes in Pin Pal", categoryName: "Notes")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigation: Navigation
    
    public func perform() async throws -> some IntentResult {
        navigation.selectedTab = .notes
        return .result()
    }
}

public struct OpenNewNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open New Note"
    public static var description: IntentDescription? = .init("Get quick access to create a note in Pin Pal", categoryName: "Notes")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigation: Navigation
    
    public func perform() async throws -> some IntentResult {
        if navigation.activeNote == nil {
            navigation.activeNote = .create()
        }
        return .result()
    }
}

public struct OpenFileImportIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Import Note"
    public static var description: IntentDescription? = .init("Get quick access to import a note in Pin Pal", categoryName: "Notes")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigation: Navigation
    
    public func perform() async throws -> some IntentResult {
        if navigation.activeNote == nil {
            navigation.fileImporterPresented = true
        }
        return .result()
    }
}

// TODO: used by composer internally

public struct UpdateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Update Note"
    
    @Parameter(title: "Identifier", description: "The identifier is from the parent memory.")
    public var identifier: String
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(identifier: String, title: String, text: String) {
        self.identifier = identifier
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var navigation: Navigation

    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !title.isEmpty else {
            throw $title.needsValueError("What would you like to update the title to?")
        }
        guard !text.isEmpty else {
            throw $text.needsValueError("What would you like to update the content to?")
        }
        guard let memoryId = UUID(uuidString: self.identifier) else {
            throw $identifier.needsValueError("What is identifier of the note to update?")
        }
        navigation.savingNote = true
        let content = try await service.update(.init(uuid: UUID(uuidString: identifier), text: text, title: title))
        let note: NoteEnvelope = content.get()!
        await database.insert(
            Note(
                uuid: note.id!,
                parentUUID: content.id,
                name: note.title,
                body: note.text,
                isFavorite: content.favorite,
                createdAt: content.userCreatedAt,
                modifedAt: content.userLastModified
            )
        )
        try await database.save()
        navigation.activeNote = nil
        navigation.savingNote = false
        return .result(value: memoryId.uuidString)
    }
}

struct SyncNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Load Notes"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
    
    public func perform() async throws -> some IntentResult {
        let chunkSize = 30
        let total = try await service.notes(0, 1).totalElements
        let totalPages = (total + chunkSize - 1) / chunkSize

        await MainActor.run {
            withAnimation {
                app.totalNotesToSync = total
            }
        }
        
        let ids = try await (0..<totalPages).concurrentMap { page in
            let data = try await service.notes(page, chunkSize)
            let result = try await data.content.concurrentMap(process)
                        
            await MainActor.run {
                withAnimation {
                    app.numberOfNotesSynced += result.count
                }
            }
                        
            return result
        }
        .flatMap({ $0 })
                        
        try await self.database.save()

        let predicate = #Predicate<Note> {
            !ids.contains($0.parentUUID)
        }
        try await self.database.delete(where: predicate)
        try await self.database.save()
        
        await MainActor.run {
            app.totalNotesToSync = 0
            app.numberOfNotesSynced = 0
        }
    

        return .result()
    }
    
    private func process(_ content: MemoryContentEnvelope) async throws -> UUID {
        guard let note: NoteEnvelope = content.get() else {
            throw Error.invalidContentType
        }
        let newNote = Note(
            uuid: note.uuid ?? .init(),
            parentUUID: content.id,
            name: note.title,
            body: note.text,
            isFavorite: content.favorite,
            createdAt: content.userCreatedAt,
            modifedAt: content.userLastModified
        )
        await self.database.insert(newNote)
        return newNote.parentUUID
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}
