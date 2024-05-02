import SwiftData
import Foundation

@Model
public final class Note {
    
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
    
    public init(from note: RemoteNote, isFavorited: Bool, createdAt: Date) {
        self.uuid = note.id
        self.memoryUuid = note.memoryId
        self.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFavorited = isFavorited
        self.createdAt = createdAt
    }
    
    public func update(using note: RemoteNote, isFavorited: Bool, createdAt: Date) {
        self.uuid = note.id
        self.memoryUuid = note.memoryId
        self.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFavorited = isFavorited
        self.createdAt = createdAt
    }
}

extension Note {
    static func newNote() -> Note {
        Note(from: .create(), isFavorited: false, createdAt: .now)
    }
}
