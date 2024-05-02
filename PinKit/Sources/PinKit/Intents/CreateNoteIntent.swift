import AppIntents

public struct CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(title: String, text: String) {
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
        var editableNote = _Note.newNote()
        let result = try await service.create(.init(text: text, title: title))
        guard let note: Note = result.get() else {
            return .result()
        }
        editableNote.update(using: note, isFavorited: false, createdAt: .now)
        await database.insert(editableNote)
        try await database.save()
        navigationStore.activeNote = nil
        return .result()
    }
}
