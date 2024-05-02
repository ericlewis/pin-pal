import SwiftData
import Foundation
import OSLog
import SwiftUI

extension _Note {
    static func newNote() -> _Note {
        _Note(from: .create(), isFavorited: false, createdAt: .now)
    }
}

@Model
public final class _Note {
    
    @Attribute(.unique)
    public var uuid: UUID? = nil
    
    public var memoryUuid: UUID? = nil
    public var title: String
    public var text: String
    public var isFavorited: Bool
    public var createdAt: Date

    public init(uuid: UUID? = nil, memoryUuid: UUID? = nil, title: String, text: String, isFavorited: Bool = false, createdAt: Date = .now) {
        self.uuid = uuid
        self.memoryUuid = memoryUuid
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFavorited = isFavorited
        self.createdAt = createdAt
    }
    
    public init(from note: Note, isFavorited: Bool, createdAt: Date) {
        self.uuid = note.id
        self.memoryUuid = note.memoryId
        self.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFavorited = isFavorited
        self.createdAt = createdAt
    }
    
    public func update(using note: Note, isFavorited: Bool, createdAt: Date) {
        self.uuid = note.id
        self.memoryUuid = note.memoryId
        self.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFavorited = isFavorited
        self.createdAt = createdAt
    }
}

struct DefaultDatabase: Database {
    struct NotImplmentedError: Error {
        static let instance = NotImplmentedError()
    }
    
    static let instance = DefaultDatabase()
    
    func fetch<T>(_: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
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

public protocol Database {
    func delete<T>(_ model: T) async where T: PersistentModel
    func insert<T>(_ model: T) async where T: PersistentModel
    func save() async throws
    func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel
    func delete<T: PersistentModel>(where predicate: Predicate<T>?) async throws
}

@ModelActor
public actor ModelActorDatabase: Database {
    public func delete(_ model: some PersistentModel) async {
        self.modelContext.delete(model)
    }
    
    public func insert(_ model: some PersistentModel) async {
        self.modelContext.insert(model)
    }
    
    public func delete<T: PersistentModel>(where predicate: Predicate<T>?) async throws {
        try self.modelContext.delete(model: T.self, where: predicate)
    }
    
    public func save() async throws {
        try self.modelContext.save()
    }
    
    public func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        return try self.modelContext.fetch(descriptor)
    }
}

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
    
    public func save() async throws {
        return try await self.database.save()
    }
}

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

public enum HumaneCloudOrigin {
    case aiBus(String)
}

public enum HumaneExperienceOrigin: String {
    case answers = "humane.experience.answers"
    case dialer = "humane.experience.dialer"
    case messages = "humane.experience.messages"
    case music = "humane.experience.music"
    case notifications = "humane.experience.notifications"
    case photography = "humane.experience.photography"
    case systemNavigation = "humane.experience.systemnavigation"
    case translation = "humane.experience.translation"
}

public enum HumaneOrigin {
    case cloud(HumaneCloudOrigin)
    case experience(HumaneExperienceOrigin)
}

public enum Origin: Codable, CustomStringConvertible {
    public var description: String {
        switch self {
        case let .unknown(value): value
        case let .humane(.cloud(.aiBus(value))): value
        case let .humane(.experience(value)): value.rawValue
        }
    }
    
    case humane(HumaneOrigin)
    case unknown(String)
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let originString = try container.decode(String.self)
        if originString.starts(with: "humane.cloud.aiBus") {
            self = .humane(.cloud(.aiBus(originString)))
        } else if originString.starts(with: "humane.experience"), let origin = HumaneExperienceOrigin(rawValue: originString) {
            self = .humane(.experience(origin))
        } else {
            self = .unknown(originString)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        
    }
}

public enum HumaneEventType: String {
    case capture = "humane.capture"
    case catchMeUp = "humane.catchMeUp"
    case createNote = "humane.createNote"
    case endCall = "humane.endCall"
    case missedCall = "humane.missedCall"
    case nearby = "humane.nearby"
    case playMusicTrack = "humane.playMusicTrack"
    case playSmartPlaylist = "humane.playSmartPlaylist"
    case receiveMessage = "humane.receiveMessage"
    case respond = "humane.respond"
    case sendMessage = "humane.sendMessage"
    case translation = "humane.translation"
    case updateNote = "humane.updateNote"
}

public enum EventType: Codable, CustomStringConvertible {
    case humane(HumaneEventType)
    case unknown(String)
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let typeString = try container.decode(String.self)
        if typeString.starts(with: "humane"), let event = HumaneEventType(rawValue: typeString) {
            self = .humane(event)
        } else {
            self = .unknown(typeString)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        
    }
    
    public var description: String {
        switch self {
        case let .humane(event): event.rawValue
        case let .unknown(event): event
        }
    }
}

public struct Event: Codable {
    public let eventIdentifier: UUID
    public let eventCreationTime: Date
    public let originatorIdentifier: Origin
    public let eventType: EventType
    public let feedbackUUID: UUID?
    public let feedbackCategory: String?
}

public struct EventStream: Codable {
    public let content: [Event]
}
