import SwiftUI
import OSLog

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

struct LoaderRow: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding()
        .listRowInsets(.init())
    }
}

struct SettingsView: View {
    struct ViewState {
        var subscription: Subscription?
        var extendedInfo: DetailedDeviceInfo?
        var isLoading = false
        var isVisionBetaEnabled = false
    }
    
    @State
    internal var state = ViewState()
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(HumaneCenterService.self)
    private var api
    
    @AppStorage(Constants.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constants.defaultAppAccentColor
    
    @AppStorage(Constants.UI_CUSTOM_APP_ICON_V1)
    private var selectedIcon: Icon = Icon.initial
    
    @Environment(\.openURL)
    private var openURL
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            Form {
                Section("Device") {
                    LabeledContent("Account Number", value: state.subscription?.accountNumber ?? "AAAAAAAAAAAAAAA")
                    LabeledContent("Phone Number", value: state.subscription?.phoneNumber ?? "1111111111")
                    LabeledContent("Status", value: state.subscription?.status ?? "ACTIVE")
                    LabeledContent("Plan", value: state.subscription?.planType ?? "DEFAULT_PLAN")
                    LabeledContent("Monthly Price") {
                        if let subscription = state.subscription {
                            Text("$\(subscription.planPrice / 100)")
                        } else {
                            Text(state.subscription?.planType ?? "$24")
                        }
                    }
                }
                .labeledContentStyle(AsyncValueLabelContentStyle(isLoading: state.subscription == nil))
                Section {
                    Toggle(isOn: $state.isVisionBetaEnabled) {
                        HStack {
                            Text("Vision")
                            Text("BETA")
                                .padding(1)
                                .padding(.horizontal, 2)
                                .font(.footnote.bold())
                                .foregroundStyle(.white)
                                .background(RoundedRectangle(cornerRadius: 5).fill(.red))
                        }
                    }
                    .disabled(state.isLoading)
                    Button("Add Wi-Fi Network") {
                        self.navigationStore.isWifiCodeGeneratorPresented = true
                    }
                    .sheet(isPresented: $navigationStore.isWifiCodeGeneratorPresented) {
                        WifiQRCodeGenView()
                    }
                    Button("Update Account Passcode") {
                        
                    }
                    .disabled(true)
                    if canDevicePlaceCalls() {
                        Button("Call your Pin") {
                            if let number = state.subscription?.phoneNumber, let url = URL(string: "tel://\(number)") {
                                openURL(url.appending(path: number))
                            }
                        }
                        .disabled(state.subscription == nil)
                    }
                    Button("Mark as Lost", role: .destructive) {
                        
                    }
                    .disabled(true)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
                }
                Section("Miscellaneous") {
                    LabeledContent("Identifier", value: state.extendedInfo?.id ?? "1F0B03041010012N")
                    LabeledContent("Serial Number", value: state.extendedInfo?.serialNumber ?? "J64M2YAH170235")
                    LabeledContent("eSIM", value: state.extendedInfo?.iccid ?? "847264928475637284")
                    LabeledContent("Color", value: (state.extendedInfo?.color ?? "ECLIPSE").localizedCapitalized)
                }
                .labeledContentStyle(AsyncValueLabelContentStyle(isLoading: state.extendedInfo == nil))
                Section("Appearance") {
                    ColorPicker("Theme", selection: $accentColor, supportsOpacity: false)
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
            }
            .refreshable {
                await load()
            }
            .navigationTitle("Settings")
        }
        .task {
            guard self.state.subscription == nil else { return }
            self.state.isLoading = true
            await load()
            self.state.isLoading = false
        }
        .onChange(of: state.isVisionBetaEnabled) {
            if !state.isLoading {
                Task {
                    try await api.toggleFeatureFlag(.visionAccess)
                }
            }
        }
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
    
    func load() async {
        do {
            do {
                let flag = try await api.featureFlag(.visionAccess)
                self.state.isVisionBetaEnabled = flag.isEnabled
            } catch {
                print(error)
            }
            let sub = try await api.subscription()
            withAnimation {
                self.state.subscription = sub
            }
            let extendedInfo = try await api.detailedDeviceInformation()
            withAnimation {
                self.state.extendedInfo = extendedInfo
            }
        } catch {
            let logger = Logger(subsystem: "app", category: "settings")
            logger.error("\(error.localizedDescription)")
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

#Preview {
    SettingsView()
        .environment(HumaneCenterService.live())
}

struct AsyncValueLabelContentStyle: LabeledContentStyle {
    
    let isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            configuration.content
                .redacted(reason: isLoading ? .placeholder : .invalidated)
                .textSelection(.enabled)
        } label: {
            configuration.label
        }
    }
}
