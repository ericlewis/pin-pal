import AppIntents

struct EditNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Note"
    
    @Parameter(title: "Id") var id: String
    @Parameter(title: "Title") var title: String
    @Parameter(title: "Text") var text: String
    
    init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
    
    init() {}
    
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true
    
    @Dependency
    var navigationStore: NavigationStore

    func perform() async throws -> some IntentResult {
        let _ = try await API.shared.update(id: id, with: .init(text: text, title: title))
        
        navigationStore.editNotePresented = false
        
        return .result()
    }
}
