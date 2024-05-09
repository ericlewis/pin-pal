import SwiftData
import Foundation

public typealias PhonePeer = SchemaV1._PhonePeer

extension SchemaV1 {
    
    @Model
    public final class _PhonePeer {
        
        @Attribute(.unique)
        public var ident: String
        
        public var phoneNumber: String
        public var displayName: String
        
        public var call: PhoneCallEvent?

        public init(phoneNumber: String, displayName: String) {
            self.ident = phoneNumber + displayName
            self.phoneNumber = phoneNumber
            self.displayName = displayName
        }
        
        public init(from peer: CallEvent.Peer) {
            self.ident = peer.phoneNumber + peer.displayName
            self.phoneNumber = peer.phoneNumber
            self.displayName = peer.displayName
        }
    }
    
}
