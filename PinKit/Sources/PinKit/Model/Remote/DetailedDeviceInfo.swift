import Foundation

public struct DetailedDeviceInfo: Codable {
    public let id: String
    public let iccid: String
    public let serialNumber: String
    public let sku: String
    public let color: String
    
    public init(id: String, iccid: String, serialNumber: String, sku: String, color: String) {
        self.id = id
        self.iccid = iccid
        self.serialNumber = serialNumber
        self.sku = sku
        self.color = color
    }
}
