import AppIntents

public struct CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    public static var description: IntentDescription? = "This action allows you to create new notes for Ai Pin."
    public static var parameterSummary: some ParameterSummary {
        Summary("Create note with \(\.$text) named \(\.$title)")
    }
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
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
    
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard !title.isEmpty else {
            throw $title.needsValueError("What is the name of the note you would like to add?")
        }
        guard !text.isEmpty else {
            throw $text.needsValueError("What is the content of the note you would like to add?")
        }
        
        try await notesRepository.create(note: .init(text: text, title: title))
        navigationStore.activeNote = nil
        
        guard let note: Note = notesRepository.content.last?.get(), let id = note.uuid?.uuidString else {
            throw AppIntentError.restartPerform
        }
        
        return .result(value: id)
    }
}
