import SwiftUI
import SwiftData

struct DefaultDatabase: Database {
    struct NotImplmentedError: Error {
        static let instance = NotImplmentedError()
    }
    
    static let instance = DefaultDatabase()
    
    func fetch<T>(_: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        assertionFailure("No Database Set.")
        throw NotImplmentedError.instance
    }
    
    func count<T>(_: FetchDescriptor<T>) async throws -> Int where T: PersistentModel {
        assertionFailure("No Database Set.")
        throw NotImplmentedError.instance
    }
    
    func delete(_: some PersistentModel) async {
        assertionFailure("No Database Set.")
    }
    
    func delete<T>(where predicate: Predicate<T>?) async throws where T : PersistentModel {
        assertionFailure("No Database Set.")
    }
    
    func insert(_: some PersistentModel) async {
        assertionFailure("No Database Set.")
    }
    
    func insert(_: [some PersistentModel]) async {
        assertionFailure("No Database Set.")
    }
    
    func save() async throws {
        assertionFailure("No Database Set.")
        throw NotImplmentedError.instance
    }
}

private struct DatabaseKey: EnvironmentKey {
  static var defaultValue: any Database {
    DefaultDatabase.instance
  }
}

public extension EnvironmentValues {
  var database: any Database {
    get { self[DatabaseKey.self] }
    set { self[DatabaseKey.self] = newValue }
  }
}
