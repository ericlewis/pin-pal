import AppIntents
import Foundation
import PinKit
import SwiftUI

struct PinPalShortcuts: AppShortcutsProvider {
    
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a new note in \(.applicationName)",
                "Create a note in \(.applicationName)",
                "Make a new note in \(.applicationName)",
                "Make a note in \(.applicationName)",
                "Start a new note in \(.applicationName)",
                "Start a note in \(.applicationName)",
                "Add a new note in \(.applicationName)",
                "Add a note in \(.applicationName)",
            ],
            shortTitle: "New Note",
            systemImageName: "square.and.pencil"
        )
    }
    
}

public struct ToggleVisionAccessIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Vision Beta"
    public static var description: IntentDescription? = .init("Turns on or off the Vision Beta access on your Ai Pin.", categoryName: "Device")
    public static var parameterSummary: some ParameterSummary {
        Summary("Vision beta is \(\.$enabled)")
    }
    
    @Parameter(title: "Enabled")
    public var enabled: Bool
    
    public init(enabled: Bool) {
        self.enabled = enabled
    }
    
    public init() {
        self.enabled = false
    }
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true

    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let device = try await database.fetch(Device.all()).first else {
            throw Error.noDevice
        }
        let newValue = enabled
        Task.detached {
            let _ = try await service.toggleFeatureFlag(.visionAccess, newValue)
        }
        device.isVisionEnabled = newValue
        try await database.save()
        return .result(value: newValue)
    }
    
    enum Error: Swift.Error {
        case noDevice
    }
}

public struct _ToggleVisionAccessIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Vision Beta"

    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false

    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let device = try await database.fetch(Device.all()).first else {
            throw Error.noDevice
        }
        let newValue = !device.isVisionEnabled
        Task.detached {
            let _ = try await service.toggleFeatureFlag(.visionAccess, newValue)
        }
        device.isVisionEnabled = newValue
        try await database.save()
        return .result(value: newValue)
    }
    
    enum Error: Swift.Error {
        case noDevice
    }
}

public struct ToggleDeviceBlockIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Device Lost or Stolen"
    public static var description: IntentDescription? = .init("Marks the device as lost or stolen.", categoryName: "Device")
    public static var parameterSummary: some ParameterSummary {
        Summary("Device is Lost or Stolen \(\.$enabled)")
    }
    
    @Parameter(title: "Enabled")
    public var enabled: Bool

    public init(isBlocked: Bool) {
        self.enabled = isBlocked
    }

    public init() {}

    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let device = try await database.fetch(Device.all()).first else {
            throw Error.noDevice
        }
        let result = try await service.toggleLostDeviceStatus(device.id, enabled)
        device.isLost = result.isLost
        try await database.save()
        return .result(value: result.isLost)
    }
    
    enum Error: Swift.Error {
        case noDevice
    }
}

public struct GetPinPhoneNumberBlockIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Phone Number"
    public static var description: IntentDescription? = .init("Retrieve the phone number associated with your Ai Pin", categoryName: "Device")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = try await service.subscription()
        return .result(value: info.phoneNumber)
    }
}

public enum WifiSecurityType: String, AppEnum {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Wi-Fi Security Type")
    public static var caseDisplayRepresentations: [WifiSecurityType: DisplayRepresentation] = [
        .wpa: "WPA",
        .wep: "WEP",
        .none: "None"
    ]
}

public struct AddWifiNetworkIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Wi-Fi Quick Setup Code"
    public static var description: IntentDescription? = .init("""
Create a QR code for use with quick setup on Ai Pin.

How to Scan:
1. Tap and hold the touchpad on your Ai Pin and say “turn on WiFi”
2. Raise your palm to activate the Laser Ink display and select “quick setup” and then “scan code”
3. Position the QR code in front of your Ai Pin to begin scanning. If successful, you should hear a chime."
""", categoryName: "Device")
    
    public static var parameterSummary: some ParameterSummary {
        When(\.$type, .equalTo, WifiSecurityType.none) {
            Summary("Create WiFi QR Code") {
                \.$name
                \.$type
                \.$hidden
            }
        } otherwise: {
            Summary("Create WiFi QR Code") {
                \.$name
                \.$type
                \.$password
                \.$hidden
            }
        }
    }
    
    @Parameter(title: "Name (SSID)")
    public var name: String
    
    @Parameter(title: "Security Type", default: WifiSecurityType.wpa)
    public var type: WifiSecurityType
    
    @Parameter(title: "Password")
    public var password: String
    
    @Parameter(title: "Is Hidden")
    public var hidden: Bool
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let image = generateQRCode(from: "WIFI:S:\(name);T:\(type.rawValue);P:\(password);H:\(hidden ? "true" : "false");;")
        guard let data = image.pngData() else {
            fatalError()
        }
        let file = IntentFile(data: data, filename: "qrCode.png")
        return .result(value: file)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 12, y: 12)
            let scaledImage2 = outputImage.transformed(by: transform, highQualityDownsample: true)
            if let cgImage = context.createCGImage(scaledImage2, from: scaledImage2.extent) {
                let res = UIImage(cgImage: cgImage)
                return res
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

public struct ShowSettingsIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Settings"
    public static var description: IntentDescription? = .init("Get quick access to settings in Pin Pal", categoryName: "Device")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigation: Navigation
    
    public func perform() async throws -> some IntentResult {
        navigation.selectedTab = .settings
        return .result()
    }
}

// MARK: Util

protocol DateSortable {
    var createdAt: Date { get }
    var modifiedAt: Date { get }
}

func filter<E: DateSortable>(content: [MemoryContentEnvelope], predicate: NSPredicate, sortedBy: [EntityQuerySort<E>]) -> [MemoryContentEnvelope] {
    Array(((content as NSArray).filtered(using: predicate) as NSArray).sortedArray(using: sortedBy.map({
        switch $0.by {
        case \E.createdAt:
            NSSortDescriptor(key: "userCreatedAt", ascending: $0.order.ascending)
        case \E.modifiedAt:
            NSSortDescriptor(key: "userLastModified", ascending: $0.order.ascending)
        default:
            NSSortDescriptor(key: "userCreatedAt", ascending: $0.order.ascending)
        }
    }))) as? [MemoryContentEnvelope] ?? []
}

// TODO: delete
extension EntityQuerySort.Ordering {
    /// Convert sort information from `EntityQuerySort` to  Foundation's `SortOrder`.
    var ascending: Bool {
        switch self {
        case .ascending:
            true
        case .descending:
            false
        }
    }
}

extension EntityQuerySort.Ordering {
    /// Convert sort information from `EntityQuerySort` to  Foundation's `SortOrder`.
    var sortOrder: SortOrder {
        switch self {
        case .ascending:
            return SortOrder.forward
        case .descending:
            return SortOrder.reverse
        }
    }
}

// MARK: Device

public struct FetchDeviceInfoIntent: AppIntent {
    public static var title: LocalizedStringResource = "Fetch Device Info"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult {
        
        let sub = try await service.subscription()
        let extendedInfo = try await service.detailedDeviceInformation()
        let flag = try await service.featureFlag(.visionAccess)
        let status = try await service.lostDeviceStatus(extendedInfo.id)
        
        let device = Device(
            id: extendedInfo.id,
            serialNumber: extendedInfo.serialNumber,
            eSIM: extendedInfo.iccid,
            status: sub.status,
            phoneNumber: sub.phoneNumber,
            color: extendedInfo.color,
            isLost: status.isLost,
            isVisionEnabled: flag.isEnabled
        )
        
        await database.insert(device)
        try await database.save()

        return .result()
    }
}

public struct _ToggleDeviceBlockIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Device Lost or Stolen"

    public init() {}

    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var navigation: Navigation
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let device = try await database.fetch(Device.all()).first else {
            throw Error.noDevice
        }
        
        if device.isLost {
            let result = try await ToggleDeviceBlockIntent(isBlocked: false).perform()
            return .result(value: result.value ?? false)
        } else {
            navigation.blockPinConfirmationPresented = true
        }
        
        return .result(value: device.isLost)
    }
    
    enum Error: Swift.Error {
        case noDevice
    }
}
