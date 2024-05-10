import SwiftData
import Foundation
import Models

public protocol EventDecodable: PersistentModel {
    var uuid: UUID { get }
    init(from event: EventContentEnvelope)
}
