import SwiftData
import Foundation

public protocol Database {
    func delete<T>(_ model: T) async where T: PersistentModel
    func insert<T>(_ model: T) async where T: PersistentModel
    func insert<T>(_ model: [T]) async where T: PersistentModel
    func save() async throws
    func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel
    func delete<T: PersistentModel>(where predicate: Predicate<T>?) async throws
}
