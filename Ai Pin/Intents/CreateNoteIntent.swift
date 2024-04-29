import AppIntents

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Note"
    
    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Text")
    var text: String
    
    init(title: String, text: String) {
        self.title = title
        self.text = text
    }
    
    init() {}
    
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true
    
    @Dependency
    var navigationStore: NavigationStore

    func perform() async throws -> some IntentResult {
        let _ = try await API.shared.create(note: .init(text: text, title: title))
        navigationStore.activeNote = nil
        return .result()
    }
}
