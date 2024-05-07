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
        try await notesRepository.update(note: Note(memoryId: memoryId, text: self.text, title: self.title))
        navigationStore.activeNote = nil
        return .result(value: memoryId.uuidString)
    }
}
