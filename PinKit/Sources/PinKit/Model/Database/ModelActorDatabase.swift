import Foundation
import SwiftData

@ModelActor
public actor ModelActorDatabase: Database {
    public func delete(_ model: some PersistentModel) async {
        self.modelContext.delete(model)
    }
    
    public func insert(_ model: some PersistentModel) async {
        self.modelContext.insert(model)
    }
    
    public func insert(_ models: [some PersistentModel]) async {
        do {
            try Task.checkCancellation()
            try self.modelContext.transaction {
                for model in models {
                    try Task.checkCancellation()
                    self.modelContext.insert(model)
                }
            }
        } catch {
            print(error)
        }
    }
    
    public func delete<T: PersistentModel>(where predicate: Predicate<T>?) async throws {
        try self.modelContext.delete(model: T.self, where: predicate)
    }
    
    public func save() async throws {
        try Task.checkCancellation()
        try self.modelContext.save()
    }
    
    public func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        return try self.modelContext.fetch(descriptor)
    }
}
