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
        let result = try await service.create(.init(text: text, title: title))
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
