import SwiftUI
import OSLog
import AppIntents
import SwiftData

struct SettingsView: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service

    @Query
    private var devices: [Device]
    
    var body: some View {
        NavigationStack {
            Form {
                if let device = devices.first {
                    Group {
                        DeviceSection()
                        FeatureSection(isVisionEnabled: device.isVisionEnabled, isLost: device.isLost)
                        LinkSection()
                        MiscSection()
                        AppearanceSections()
                        DangerZoneSection()
                    }
                    .environment(device)
                }
            }
            .refreshable(action: load)
            .navigationTitle("Settings")
        }
        .task(load)
        .overlay {
            if devices.isEmpty {
                ProgressView()
            }
        }
    }
    
    func load() async {
        do {
            let intent = FetchDeviceInfoIntent()
            intent.database = database
            intent.service = service
            try await intent.perform()
        } catch {}
    }
}

struct DeviceSection: View {
    
    @Environment(Device.self)
    private var device
    
    var body: some View {
        Section() {
            let text = device.phoneNumber.formatPhoneNumber() ?? "1111111111"
            LabeledContent("Phone Number") {
                if canDevicePlaceCalls(), let number = device.phoneNumber.telephoneUrl() {
                    Link(text, destination: number)
                } else {
                    Text(text)
                }
            }
            .contextMenu {
                if canDevicePlaceCalls(), let number = device.phoneNumber.telephoneUrl() {
                    Button("Copy Phone Number", systemImage: "doc.on.doc") {
                        UIPasteboard.general.url = number
                    }
                    Link(destination: number) {
                        Label("Call \(text)", systemImage: "phone")
                    }
                }
            }
            LabeledContent("Status", value: device.status ?? "ACTIVE")
        } header: {
            Text("Device")
        } footer: {
            Link("Subscription \(Image(systemName: "arrow.up.right.square"))", destination: .init(string: "https://humane.center/account/subscription")!)
                .font(.footnote.bold())
                .imageScale(.small)
        }
    }
    
    func canDevicePlaceCalls() -> Bool {
        if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
            return true
        } else {
            return false
        }
    }
}

struct FeatureSection: View {
    
    var isVisionEnabled: Bool
    var isLost: Bool

    @Environment(NavigationStore.self)
    private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        Section {
            Toggle(isOn: isVisionEnabled, intent: _ToggleVisionAccessIntent()) {
                HStack {
                    Text("Vision")
                    BetaLabel()
                }
            }
            Button("Add Wi-Fi Network") {
                self.navigation.isWifiCodeGeneratorPresented = true
            }
            .sheet(isPresented: $navigation.isWifiCodeGeneratorPresented) {
                WifiQRCodeGenView()
            }
            Toggle("Mark device as lost or stolen", isOn: isLost, intent: _ToggleDeviceBlockIntent())
                .alert("Lost or Stolen Ai Pin", isPresented: $navigation.blockPinConfirmationPresented) {
                    Button("Block Pin", role: .destructive, intent: ToggleDeviceBlockIntent(isBlocked: true))
                    Button("Cancel", role: .cancel) {
                        navigation.blockPinConfirmationPresented = false
                    }
                } message: {
                    Text("""
        Enable “Block my device” if your Ai Pin is lost or stolen. While in this mode, if someone tries to use your device, it will instantly lock your Ai Pin—keeping your encrypted data on Humane’s servers safe and secure.

        Once your device has been recovered, turn this setting off.
        """)
                }
        } header: {
            Text("Features")
        } footer: {
            Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
        }
    }
}

struct LinkSection: View {
    var body: some View {
        Section {
            Link(destination: .init(string: "https://humane.center/account/services")!) {
                LabeledContent("Services") {
                    Image(systemName: "arrow.up.right.square")
                }
            }
            Link(destination: .init(string: "https://humane.center/contacts")!) {
                LabeledContent("Contacts") {
                    Image(systemName: "arrow.up.right.square")
                }
            }
            Link(destination: .init(string: "https://humane.com/changelog")!) {
                LabeledContent("Change Log") {
                    Image(systemName: "arrow.up.right.square")
                }
            }
            Link(destination: .init(string: "https://support.humane.com/")!) {
                LabeledContent("Support") {
                    Image(systemName: "arrow.up.right.square")
                }
            }
        } header: {
            Text(".Center")
        } footer: {
            Text("Please keep in mind Pin Pal is not an official app, the Support team cannot help with any app issues.")
        }
    }
}

struct MiscSection: View {
    
    @Environment(Device.self)
    private var device
    
    var body: some View {
        Section("Miscellaneous") {
            LabeledContent("Identifier", value: device.id)
            LabeledContent("Serial Number", value: device.serialNumber)
            LabeledContent("eSIM", value: device.eSIM)
            LabeledContent("Color", value: device.color.localizedCapitalized)
        }
    }
}

struct AppearanceSections: View {
    
    
    @AccentColor
    private var accentColor: Color
    
    
    @AppStorage(Constants.UI_CUSTOM_APP_ICON_V1)
    private var selectedIcon: Icon = Icon.initial
    
    @AppStorage(Constants.UI_DATE_FORMAT)
    private var dateFormatPreference: DateFormat = .relative
    
    
    var body: some View {
        Section("Appearance") {
            ColorPicker("Theme", selection: $accentColor, supportsOpacity: false)
            Picker("Date Format", selection: $dateFormatPreference) {
                Text("Relative").tag(DateFormat.relative)
                Text("Timestamp").tag(DateFormat.timestamp)
            }
            .id(accentColor)
        }
#if os(iOS)
        Picker("App Icon", selection: $selectedIcon) {
            ForEach(Icon.allCases) { icon in
                HStack {
                    Image(icon.description.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(icon.description.title)
                }
            }
        }
        .pickerStyle(.inline)
        .onChange(of: selectedIcon) {
            if selectedIcon.description.iconName == Constants.defaultAppIconName {
                UIApplication.shared.setAlternateIconName(nil)
            } else {
                UIApplication.shared.setAlternateIconName(selectedIcon.description.iconName)
            }
        }
#endif
    }
}

struct DangerZoneSection: View {
     
    @Environment(NavigationStore.self)
    private var navigation
    
    var body: some View {
        @Bindable var navigation = navigation
        Section {
            Button("Delete all notes", role: .destructive, intent: _DeleteAllNotesIntent())
                .alert("Are you sure?", isPresented: $navigation.deleteAllNotesConfirmationPresented) {
                    Button("Delete", role: .destructive, intent: DeleteAllNotesIntent(confirmBeforeDeleting: false))
                    Button("Cancel", role: .cancel) {
                        navigation.deleteAllNotesConfirmationPresented = false
                    }
                } message: {
                    Text("This operation is irreversible, all notes will be deleted!")
                }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text(version())
        }
    }
    
    func version() -> String {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String,
              let build = dictionary["CFBundleVersion"] as? String else {
            return ""
        }
        
        return "\(version) (\(build))"
    }
}

enum Icon: String, CaseIterable, Identifiable {
    case initial, deviceIcon
    var id: Self { self }
}

struct IconDescription {
    var title: String
    var iconName: String
    var imageName: String
}

extension Icon {
    var description: IconDescription {
        switch self {
        case .initial: return IconDescription(title: "Sensors", iconName: "", imageName: "AppIconPreview")
        case .deviceIcon: return IconDescription(title: "Ai Pin", iconName: "DeviceAppIcon", imageName: "DeviceAppIconPreview")
        }
    }
}

struct AsyncValueLabelContentStyle: LabeledContentStyle {
    
    let isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            configuration.content
                .redacted(reason: isLoading ? .placeholder : .invalidated)
                .textSelection(.enabled)
                .privacySensitive(true)
        } label: {
            configuration.label
        }
    }
}

struct BetaLabel: View {
    var body: some View {
        Text("BETA")
            .padding(1)
            .padding(.horizontal, 2)
            .font(.footnote.bold())
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 5).fill(.red))
    }
}

enum DateFormat: String {
    case relative
    case timestamp
}

extension String {
    func formatPhoneNumber() -> String {
        let cleanNumber = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let mask = "(XXX) XXX-XXXX"
        
        var result = ""
        var startIndex = cleanNumber.startIndex
        var endIndex = cleanNumber.endIndex
        
        for char in mask where startIndex < endIndex {
            if char == "X" {
                result.append(cleanNumber[startIndex])
                startIndex = cleanNumber.index(after: startIndex)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    func telephoneUrl() -> URL? {
        URL(string: "tel://\(self)")
    }
}

#Preview {
    SettingsView()
        .environment(HumaneCenterService.live())
}
