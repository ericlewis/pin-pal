import AppIntents

public struct ToggleVisionAccessIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle vision access"
    
    @Parameter(title: "Enabled")
    public var enabled: Bool
    
    public init(enabled: Bool) {
        self.enabled = enabled
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let response = try await service.toggleFeatureFlag(.visionAccess, enabled)
        return .result(value: response.isEnabled)
    }
}
