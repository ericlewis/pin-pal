import Foundation

public struct DetailedDeviceInfo: Codable {
    let id: String
    let iccid: String
    let serialNumber: String
    let sku: String
    let color: String
    
    public init(id: String, iccid: String, serialNumber: String, sku: String, color: String) {
        self.id = id
        self.iccid = iccid
        self.serialNumber = serialNumber
        self.sku = sku
        self.color = color
    }
}
