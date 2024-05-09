import SwiftData
import Foundation

public typealias PhonePeer = SchemaV1.PhonePeer

extension SchemaV1 {
    
    @Model
    public final class PhonePeer {
        
        @Attribute(.unique)
        public var phoneNumber: String
        
        public var displayName: String

        public init(phoneNumber: String, displayName: String) {
            self.phoneNumber = phoneNumber
            self.displayName = displayName
        }
        
        public init(from peer: CallEvent.Peer) {
            self.phoneNumber = peer.phoneNumber
            self.displayName = peer.displayName
        }
    }
    
}
