import AppIntents
import SwiftData

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
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        guard let memoryId = UUID(uuidString: self.identifier) else {
            return .result()
        }
        let result = try await service.update(memoryId.uuidString, RemoteNote(text: self.text, title: self.title))
        guard let remoteNote: RemoteNote = result.get() else {
            return .result()
        }
        let memory = Memory(uuid: result.uuid, favorite: result.favorite, createdAt: result.userCreatedAt)
        let note = Note(
            uuid: remoteNote.uuid,
            title: remoteNote.title,
            text: remoteNote.text,
            createdAt: result.userCreatedAt
        )
        memory.note = note
        await database.insert(memory)
        try await database.save()
        navigationStore.activeNote = nil
        return .result()
    }
}
