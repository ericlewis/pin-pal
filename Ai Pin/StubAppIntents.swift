import AppIntents
import PinKit

// NOTE: we have to duplicate our intents in the app package... for... reasons?

public struct _CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        try await CreateNoteIntent(title: title, text: text).perform()
    }
}

public struct _UpdateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Update Note"
    
    @Parameter(title: "Identifier", description: "The identifier is from the parent memory.")
    public var identifier: String
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        try await UpdateNoteIntent(identifier: identifier, title: title, text: text).perform()
    }
}
