import AppIntents

struct UpdateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Note"
    
    @Parameter(title: "Identifier", description: "The identifier is from the parent memory.")
    var identifier: String
    
    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Text")
    var text: String
    
    init(identifier: String, title: String, text: String) {
        self.identifier = identifier
        self.title = title
        self.text = text
    }
    
    init() {}
    
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true
    
    @Dependency
    var navigationStore: NavigationStore

    func perform() async throws -> some IntentResult {
        let _ = try await API.shared.update(id: self.identifier, with: .init(text: self.text, title: self.title))
        navigationStore.composerNote = nil
        return .result()
    }
}
