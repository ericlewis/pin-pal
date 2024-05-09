import Foundation

public struct Subscription: Codable {
    let status: String
    public let phoneNumber: String
    let accountNumber: String
    let planType: String
    let pinSetAt: Date?
    let planPrice: Int
    
    public init(
        status: String,
        phoneNumber: String,
        accountNumber: String,
        planType: String,
        pinSetAt: Date?,
        planPrice: Int
    ) {
        self.status = status
        self.phoneNumber = phoneNumber
        self.accountNumber = accountNumber
        self.planType = planType
        self.pinSetAt = pinSetAt
        self.planPrice = planPrice
    }
}
