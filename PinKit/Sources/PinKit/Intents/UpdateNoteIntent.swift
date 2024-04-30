import AppIntents

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
        self.title = title
        self.text = text
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var notesRepository: NotesRepository
    
    public func perform() async throws -> some IntentResult {
        guard let memoryId = UUID(uuidString: self.identifier) else {
            return .result()
        }
        try await notesRepository.update(note: Note(memoryId: memoryId, text: self.text, title: self.title))
        navigationStore.activeNote = nil
        return .result()
    }
}
