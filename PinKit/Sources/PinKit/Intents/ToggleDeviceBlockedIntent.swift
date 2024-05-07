import AppIntents

public struct ToggleDeviceBlockedIntent: AppIntent {
    public static var title: LocalizedStringResource = "Block device"
    
    @Parameter(title: "Device ID")
    public var deviceId: String
    
    @Parameter(title: "Blocked")
    public var blocked: Bool
    
    public init(deviceId: String, blocked: Bool) {
        self.deviceId = deviceId
        self.blocked = blocked
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let response = try await service.toggleLostDeviceStatus(deviceId, blocked)
        return .result(value: response.isLost)
    }
}
