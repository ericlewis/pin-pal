import Foundation

public struct PageableContentEnvelope<C: Codable>: Codable {
    
    public struct Pageable: Codable {
        
        public struct Sort: Codable {
            let empty: Bool
            let sorted: Bool
            let unsorted: Bool
        }
        
        let unpaged: Bool
        let pageNumber: Int
        let offset: Int
        let sort: Sort
        let pageSize: Int
        let paged: Bool
    }
    
    let number: Int
    public var content: [C]
    let pageable: Pageable
    let sort: Pageable.Sort
    let numberOfElements: Int
    let totalPages: Int
    let size: Int
    let last: Bool
    let empty: Bool
    public let totalElements: Int
    let first: Bool
}

public typealias PageableMemoryContentEnvelope = PageableContentEnvelope<MemoryContentEnvelope>
public typealias PageableEventContentEnvelope = PageableContentEnvelope<EventContentEnvelope>
