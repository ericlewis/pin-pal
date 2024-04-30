import Foundation

public struct Addon: Codable {
    let provisionedSuccessfully: Bool?
    let price: Int?
    let name: String
    let provisioningStatus: String?
    let days: Int?
    let dataThrottling: Double?
    let displayName, spid, optionType: String
    let oneTimeAddon: Bool
    let timeToLiveInDays: Int
    let billingCycle: String?
    let auxiliaryBundles: [String]?
}
