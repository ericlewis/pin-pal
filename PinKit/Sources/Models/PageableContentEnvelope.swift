import Foundation

public struct PageableContentEnvelope<C: Codable>: Codable {
    
    public struct Pageable: Codable {
        
        public struct Sort: Codable {
            public let empty: Bool
            public let sorted: Bool
            public let unsorted: Bool
        }
        
        public let unpaged: Bool
        public let pageNumber: Int
        public let offset: Int
        public let sort: Sort
        public let pageSize: Int
        public let paged: Bool
    }
    
    public let number: Int
    public var content: [C]
    public let pageable: Pageable
    public let sort: Pageable.Sort
    public let numberOfElements: Int
    public let totalPages: Int
    public let size: Int
    public let last: Bool
    public let empty: Bool
    public let totalElements: Int
    public let first: Bool
}

public typealias PageableMemoryContentEnvelope = PageableContentEnvelope<MemoryContentEnvelope>
public typealias PageableEventContentEnvelope = PageableContentEnvelope<EventContentEnvelope>
