import SwiftData
import Foundation

public class BackgroundDatabase: Database {
    private actor DatabaseContainer {
        private let factory: @Sendable () -> any Database
        private var wrappedTask: Task<any Database, Never>?
        
        fileprivate init(factory: @escaping @Sendable () -> any Database) {
            self.factory = factory
        }
        
        fileprivate var database: any Database {
            get async {
                if let wrappedTask {
                    return await wrappedTask.value
                }
                let task = Task {
                    factory()
                }
                self.wrappedTask = task
                return await task.value
            }
        }
    }
    
    private let container: DatabaseContainer
    
    private var database: any Database {
        get async {
            await container.database
        }
    }
    
    internal init(_ factory: @Sendable @escaping () -> any Database) {
        self.container = .init(factory: factory)
    }
    
    convenience init(modelContainer: ModelContainer) {
        self.init {
            return ModelActorDatabase(modelContainer: modelContainer)
        }
    }

    public func delete<T>(where predicate: Predicate<T>?) async throws where T : PersistentModel {
        try await self.database.delete(where: predicate)
    }
    
    public func delete<T>(_ model: T) async where T : PersistentModel {
        try await self.database.delete(model)
    }
    
    public func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        return try await self.database.fetch(descriptor)
    }
    
    public func insert(_ model: some PersistentModel) async {
        return await self.database.insert(model)
    }
    
    public func insert<T>(_ model: [T]) async where T : PersistentModel {
        return await self.database.insert(model)
    }
    
    public func save() async throws {
        return try await self.database.save()
    }
}
