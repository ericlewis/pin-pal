import AppIntents

public struct CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(title: String, text: String) {
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
        let _ = try await notesRepository.create(note: .init(text: text, title: title))
        navigationStore.activeNote = nil
        return .result()
    }
}
