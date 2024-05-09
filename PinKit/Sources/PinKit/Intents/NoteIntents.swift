import AppIntents
import PinKit

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

    public init(from content: ContentEnvelope) {
        let note: Note = content.get()!
        self.id = note.memoryId!
        self.createdAt = note.createdAt!
        self.modifiedAt = note.modifiedAt!
        self.title = note.title
        self.text = note.text
    }
    
    public init(from note: _Note) {
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
        try await database.fetch(_Note.all())
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
        var descriptor = _Note.all()
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
    
    public init(note: _Note) {
        self.target = .init(from: note)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore

    public func perform() async throws -> some IntentResult {
        navigationStore.activeNote = .init(
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
    public var navigationStore: NavigationStore

    @Dependency
    public var database: any Database
    
    @Dependency
    public var service: HumaneCenterService
    
    public func perform() async throws -> some IntentResult {
        let content = try await service.create(.init(text: text, title: title))
        let note: Note = content.get()!
        await database.insert(
            _Note(
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
        navigationStore.activeNote = nil
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
    
    public init(action: FavoriteAction, notes: [_Note]) {
        self.action = action
        self.notes = notes.map(NoteEntity.init(from:))
    }
    
    public init(action: FavoriteAction, note: _Note) {
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
                guard let note: Note = content.get() else {
                    return
                }
                await self.database.insert(_Note(
                    uuid: note.uuid ?? .init(),
                    parentUUID: content.id,
                    name: note.title,
                    body: note.text,
                    isFavorite: content.favorite,
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
        let content = try await service.update(note.id.uuidString, .init(text: newBody, title: note.title))
        let note: Note = content.get()!
        await database.insert(
            _Note(
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
    
    public init(entities: [_Note], confirmBeforeDeleting: Bool) {
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
        
        try await database.delete(where: #Predicate<_Note> {
            ids.contains($0.parentUUID)
        })
        try await database.save()
        
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
        try await .result(value: .init(from: service.update(note.id.uuidString, .init(text: body, title: note.title))))
    }
}

public struct ShowNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Notes"
    public static var description: IntentDescription? = .init("Get quick access to notes in Pin Pal", categoryName: "Notes")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigationStore: NavigationStore
    
    public func perform() async throws -> some IntentResult {
        navigationStore.selectedTab = .notes
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
    public var navigationStore: NavigationStore
    
    public func perform() async throws -> some IntentResult {
        if navigationStore.activeNote == nil {
            navigationStore.activeNote = .create()
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
    public var navigationStore: NavigationStore

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
        
        let content = try await service.update(identifier, .init(text: text, title: title))
        let note: Note = content.get()!
        await database.insert(
            _Note(
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
        navigationStore.activeNote = nil
        return .result(value: memoryId.uuidString)
    }
}

struct LoadNotesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Load Notes"
    
    @Parameter(title: "Page")
    public var page: Int
    
    @Parameter(title: "Page Size")
    public var pageSize: Int
    
    public init(page: Int, pageSize: Int = 15) {
        self.page = page
        self.pageSize = pageSize
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    public func perform() async throws -> some IntentResult {
        let total = try await service.notes(page, 1).totalElements
        let data = try await service.notes(0, total)
        await data.content.concurrentForEach { content in
            guard let note: Note = content.get() else {
                return
            }
            await self.database.insert(_Note(
                uuid: note.uuid ?? .init(),
                parentUUID: content.id,
                name: note.title,
                body: note.text,
                isFavorite: content.favorite,
                createdAt: content.userCreatedAt,
                modifedAt: content.userLastModified)
            )
        }
        try await self.database.save()
        return .result()
    }
}
