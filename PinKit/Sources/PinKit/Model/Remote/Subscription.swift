import Foundation

public struct Subscription: Codable {
    let status: String
    let phoneNumber: String
    let accountNumber: String
    let planType: String
    let defaultPaymentMethod: PaymentMethod
    let pinSetAt: Date?
    let planPrice: Int
    
    public init(
        status: String,
        phoneNumber: String,
        accountNumber: String,
        planType: String,
        defaultPaymentMethod: PaymentMethod,
        pinSetAt: Date?,
        planPrice: Int
    ) {
        self.status = status
        self.phoneNumber = phoneNumber
        self.accountNumber = accountNumber
        self.planType = planType
        self.defaultPaymentMethod = defaultPaymentMethod
        self.pinSetAt = pinSetAt
        self.planPrice = planPrice
    }
}
