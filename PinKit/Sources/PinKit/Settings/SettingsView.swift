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
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor

    @AppStorage(Constant.UI_CUSTOM_APP_ICON_V1)
    private var selectedIcon: Icon = Icon.initial
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            Form {
                Section("Device") {
                    if let subscription = state.subscription {
                        LabeledContent("Account Number", value: subscription.accountNumber)
                        LabeledContent("Phone Number", value: subscription.phoneNumber)
                        LabeledContent("Status", value: subscription.status)
                        LabeledContent("Plan", value: subscription.planType)
                        LabeledContent("Monthly Price", value: "$\(subscription.planPrice / 100)")
                    } else {
                        LoaderRow()
                    }
                }
                .textSelection(.enabled)
                Section("Features") {
                    Toggle("Vision (Beta)", isOn: $state.isVisionBetaEnabled)
                    Button("Add Wi-Fi Network") {
                        self.navigationStore.isWifiCodeGeneratorPresented = true
                    }
                    .sheet(isPresented: $navigationStore.isWifiCodeGeneratorPresented) {
                        WifiQRCodeGenView()
                    }
                    Button("Update Passcode") {
                        
                    }
                }
                .disabled(state.isLoading)
                Section {
                    Button("Mark As Lost", role: .destructive) {
                        
                    }
                    .disabled(state.isLoading)
                } header: {
                    Text("Security")
                } footer: {
                    Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
                }
                Section("Miscellaneous") {
                    if let extendedInfo = state.extendedInfo {
                        LabeledContent("Identifier", value: extendedInfo.id)
                        LabeledContent("Serial Number", value: extendedInfo.serialNumber)
                        LabeledContent("eSIM", value: extendedInfo.iccid)
                        LabeledContent("Color", value: extendedInfo.color)
                    } else {
                        LoaderRow()
                    }
                }
                .textSelection(.enabled)
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
            self.state.isLoading = true
            await load()
            self.state.isLoading = false
        }
        .onChange(of: state.isVisionBetaEnabled) {
            if !state.isLoading {
                // TODO: handle vision toggle
            }
        }
        .onChange(of: selectedIcon) {
            #if os(iOS)
            if selectedIcon.description.iconName == Constant.defaultAppIconName {
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
                let flag = try await api.featureFlag("visionAccess")
                self.state.isVisionBetaEnabled = flag.bool
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
}

#Preview {
    SettingsView()
        .environment(HumaneCenterService.live())
}
