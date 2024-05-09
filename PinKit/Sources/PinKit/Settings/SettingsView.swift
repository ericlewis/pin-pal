import SwiftUI
import OSLog
import AppIntents

enum DateFormat: String {
    case relative
    case timestamp
}

struct SettingsView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(SettingsRepository.self)
    private var repository
    
    @AccentColor
    private var accentColor: Color
    
    @AppStorage(Constants.UI_CUSTOM_APP_ICON_V1)
    private var selectedIcon: Icon = Icon.initial
    
    @AppStorage(Constants.UI_DATE_FORMAT)
    private var dateFormatPreference: DateFormat = .relative
    
    @State
    private var deleteAllNotesConfirmationPresented = false
    
    @State
    private var blockPinConfirmationPresented = false
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        @Bindable var repository = repository
        NavigationStack {
            Form {
                Section() {
                    let text = repository.subscription?.phoneNumber.formatPhoneNumber() ?? "1111111111"
                    LabeledContent("Phone Number") {
                        if canDevicePlaceCalls(), let number = repository.subscription?.phoneNumber.telephoneUrl() {
                            Link(text, destination: number)
                        } else {
                            Text(text)
                        }
                    }
                    .contextMenu {
                        if canDevicePlaceCalls(), let number = repository.subscription?.phoneNumber.telephoneUrl() {
                            Button("Copy Phone Number", systemImage: "doc.on.doc") {
                                UIPasteboard.general.url = number
                            }
                            Link(destination: number) {
                                Label("Call \(text)", systemImage: "phone")
                            }
                        }
                    }
                    LabeledContent("Status", value: repository.subscription?.status ?? "ACTIVE")
                } header: {
                    Text("Device")
                } footer: {
                    Link("Subscription Details \(Image(systemName: "arrow.up.right.square"))", destination: .init(string: "https://humane.center/account/subscription")!)
                        .font(.footnote.bold())
                        .imageScale(.small)
                }
                .labeledContentStyle(AsyncValueLabelContentStyle(isLoading: repository.subscription == nil))
                Section {
                    Toggle(isOn: repository.isVisionBetaEnabled, intent: _ToggleVisionAccessIntent()) {
                        HStack {
                            Text("Vision")
                            BetaLabel()
                        }
                    }
                    .disabled(repository.isLoading)
                    Button("Add Wi-Fi Network") {
                        self.navigationStore.isWifiCodeGeneratorPresented = true
                    }
                    .sheet(isPresented: $navigationStore.isWifiCodeGeneratorPresented) {
                        WifiQRCodeGenView()
                    }
                    Toggle("Mark device as lost or stolen", isOn: .constant(repository.isDeviceLost))
                        .onTapGesture(perform: {
                            if repository.isDeviceLost, let id = repository.extendedInfo?.id {
                                Task {
                                    try await service.toggleLostDeviceStatus(id, false)
                                    repository.isDeviceLost = false
                                }
                            } else {
                                self.blockPinConfirmationPresented = true
                            }
                        })
                        .disabled(repository.isLoading)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
                }
                Section(".Center") {
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
                }
                Section("Miscellaneous") {
                    let info = repository.extendedInfo
                    LabeledContent("Identifier", value: info?.id ?? "1F0B03041010012N")
                    LabeledContent("Serial Number", value: info?.serialNumber ?? "J64M2YAH170235")
                    LabeledContent("eSIM", value: info?.iccid ?? "847264928475637284")
                    LabeledContent("Color", value: (info?.color ?? "ECLIPSE").localizedCapitalized)
                }
                .labeledContentStyle(AsyncValueLabelContentStyle(isLoading: repository.extendedInfo == nil))
                Section("Appearance") {
                    ColorPicker("Theme", selection: $accentColor, supportsOpacity: false)
                    Picker("Date Format", selection: $dateFormatPreference) {
                        Text("Relative").tag(DateFormat.relative)
                        Text("Timestamp").tag(DateFormat.timestamp)
                    }
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
#endif
                Section {
                    Button("Delete all notes", role: .destructive) {
                        self.deleteAllNotesConfirmationPresented = true
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text(version())
                }
            }
            .refreshable(action: repository.reload)
            .navigationTitle("Settings")
            .alert("Are you sure?", isPresented: $deleteAllNotesConfirmationPresented) {
                Button("Delete", role: .destructive) {
                    Task {
                        await repository.deleteAllNotes()
                    }
                    deleteAllNotesConfirmationPresented = false
                }
                Button("Cancel", role: .cancel) {
                    deleteAllNotesConfirmationPresented = false
                }
            } message: {
                Text("This operation is irreversible, all notes will be deleted!")
            }
            .alert("Lost or Stolen Ai Pin", isPresented: $blockPinConfirmationPresented) {
                Button("Block Pin", role: .destructive, intent: ToggleDeviceBlockIntent(isBlocked: true))
                Button("Cancel", role: .cancel) {
                    blockPinConfirmationPresented = false
                }
            } message: {
                Text("""
Enable “Block my device” if your Ai Pin is lost or stolen. While in this mode, if someone tries to use your device, it will instantly lock your Ai Pin—keeping your encrypted data on Humane’s servers safe and secure.

Once your device has been recovered, turn this setting off.
""")
            }
        }
        .task(repository.initial)
        .onChange(of: selectedIcon) {
#if os(iOS)
            if selectedIcon.description.iconName == Constants.defaultAppIconName {
                UIApplication.shared.setAlternateIconName(nil)
            } else {
                UIApplication.shared.setAlternateIconName(selectedIcon.description.iconName)
            }
#endif
        }
    }

    func canDevicePlaceCalls() -> Bool {
        if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
            return true
        } else {
            return false
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

#Preview {
    SettingsView()
        .environment(HumaneCenterService.live())
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
