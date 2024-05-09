import SwiftData
import Foundation

extension SchemaV1 {
    
    @Model
    public final class Device {
        
        @Attribute(.unique)
        public var id: String
        
        public var serialNumber: String
        public var eSIM: String
        public var status: String
        public var phoneNumber: String
        public var color: String
        public var isLost: Bool
        public var isVisionEnabled: Bool
        
        public init(
            id: String,
            serialNumber: String,
            eSIM: String,
            status: String,
            phoneNumber: String,
            color: String,
            isLost: Bool,
            isVisionEnabled: Bool
        ) {
            self.id = id
            self.serialNumber = serialNumber
            self.eSIM = eSIM
            self.status = status
            self.phoneNumber = phoneNumber
            self.color = color
            self.isLost = isLost
            self.isVisionEnabled = isVisionEnabled
        }
    }
    
}
