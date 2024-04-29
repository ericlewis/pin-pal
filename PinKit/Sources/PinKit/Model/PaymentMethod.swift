import Foundation

public struct PaymentMethod: Codable {
    let last4: String
    let brand: String
    let source: String
}
