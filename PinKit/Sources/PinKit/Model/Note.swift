import SwiftData
import Foundation

@Model
public final class Note {
    
    @Attribute(.unique)
    public var uuid: UUID? = nil
    
    var memory: Memory?
    
    public var title: String
    public var text: String
    public var createdAt: Date

    public init(uuid: UUID? = nil, memory: Memory? = nil, title: String, text: String, isFavorited: Bool = false, createdAt: Date) {
        self.uuid = uuid
        self.memory = memory
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}

extension Note {
    static func newNote() -> Note {
        .init(title: "", text: "", createdAt: .now)
    }
}
