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
    
    public static var openAppWhenRun: Bool = true
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
        let content = try await service.update(memoryId.uuidString, Note(text: self.text, title: self.title))
        var editableNote = _Note.newNote()
        editableNote.update(using: content.get()!, isFavorited: content.favorite, createdAt: content.userCreatedAt)
        await database.insert(editableNote)
        try await database.save()
        navigationStore.activeNote = nil
        return .result()
    }
}
