import SwiftData
import Foundation

public typealias PhonePeer = SchemaV1.PhonePeer

extension SchemaV1 {
    
    @Model
    public final class PhonePeer {
        
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
        
        public init(from peer: RemoteCallEvent.Peer) {
            self.ident = peer.phoneNumber + peer.displayName
            self.phoneNumber = peer.phoneNumber
            self.displayName = peer.displayName
        }
    }
    
}
