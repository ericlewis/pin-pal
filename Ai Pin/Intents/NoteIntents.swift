import AppIntents
import Foundation
import PinKit
import SwiftUI

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
        try await service.notes(0, 1000)
            .content
            .concurrentMap(NoteEntity.init(from:))
    }
    public static var findIntentDescription: IntentDescription? {
        .init("", categoryName: "Notes")
    }
    
    @Dependency
    var service: HumaneCenterService
    
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
        try await service.notes(0, 30)
            .content
            .map(NoteEntity.init(from:))
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
    public var notesRepository: NotesRepository
    
    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> & ProvidesDialog {
        await notesRepository.create(note: .init(text: text, title: title))
        navigationStore.activeNote = nil
        
        guard let note = notesRepository.content.first else {
            fatalError()
        }
        
        return .result(value: .init(from: note), dialog: .init("Added your note."))
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

    public func perform() async throws -> some IntentResult & ReturnsValue<NoteEntity> {
        let newBody = """
    \(note.text)
    \(text)
    """
        return try await .result(value: .init(from: service.update(note.id.uuidString, .init(text: newBody, title: note.title))))
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
    
    public init(notes: [NoteEntity]) {
        self.entities = notes
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

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
    
    public init(notes: [NoteEntity]) {
        self.notes = notes
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        let ids = notes.map(\.id)
        if action == .add {
            let _ = try await service.bulkFavorite(ids)
        } else {
            let _ = try await service.bulkUnfavorite(ids)
        }
        return .result()
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
        navigationStore.activeNote = .create()
        return .result()
    }
}
