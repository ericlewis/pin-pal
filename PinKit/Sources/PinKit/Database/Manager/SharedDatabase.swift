import SwiftData

public struct SharedDatabase {
    public let modelContainer: ModelContainer
    public let database: any Database
    
    public init(
        modelContainer: ModelContainer,
        database: (any Database)? = nil
    ) {
        self.modelContainer = modelContainer
        self.database = database ?? BackgroundDatabase(modelContainer: modelContainer)
    }
}
