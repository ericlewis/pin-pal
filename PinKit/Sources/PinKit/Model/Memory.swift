import Foundation
import SwiftData
import CoreLocation

@Model
public final class Location {
    
    @Attribute(.unique)
    var name: String
    
    var latitude: Double
    
    var longitude: Double
    
    @Relationship(deleteRule: .nullify, inverse: \Memory.location)
    var memories: [Memory]
    
    var coordinates: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
    
    init(name: String, latitude: Double, longitude: Double, memories: [Memory] = []) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.memories = memories
    }
}

@Model
public final class Memory {
    
    static let all = FetchDescriptor<Memory>()
    static func id(_ id: UUID) -> FetchDescriptor<Memory> {
        let predicate = #Predicate<Memory> {
            $0.uuid == id
        }
        return FetchDescriptor<Memory>(predicate: predicate)
    }
    
    @Attribute(.unique)
    var uuid: UUID
    
    var favorite: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Capture.memory)
    var capture: Capture?
    
    @Relationship(deleteRule: .cascade, inverse: \Note.memory)
    var note: Note?
    
    var location: Location?
    
    init(
        uuid: UUID,
        favorite: Bool,
        createdAt: Date,
        capture: Capture? = nil,
        note: Note? = nil,
        location: Location? = nil
    ) {
        self.uuid = uuid
        self.favorite = favorite
        self.createdAt = createdAt
        self.capture = capture
        self.note = note
        self.location = location
    }
}
