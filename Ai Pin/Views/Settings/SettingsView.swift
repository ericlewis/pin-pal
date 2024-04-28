import SwiftUI
import OSLog

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
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor

    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            List {
                if let subscription = state.subscription {
                    Section("Device") {
                        LabeledContent("Account Number", value: subscription.accountNumber)
                        LabeledContent("Phone Number", value: subscription.phoneNumber)
                        LabeledContent("Status", value: subscription.status)
                        LabeledContent("Plan", value: subscription.planType)
                        LabeledContent("Monthly Price", value: "$\(subscription.planPrice / 100)")
                    }
                    
                    .textSelection(.enabled)
                    Section("Features") {
                        Toggle("Vision (Beta)", isOn: $state.isVisionBetaEnabled)
                            .disabled(state.isLoading)
                        Button("Add Wi-Fi Network") {
                            self.navigationStore.isWifiPresented = true
                        }
                        .sheet(isPresented: $navigationStore.isWifiPresented) {
                            WifiQRCodeGenView()
                        }
                        Button("Update Passcode") {
                            
                        }
                    }
                    
                    Section {
                        Button("Mark As Lost", role: .destructive) {
                            
                        }
                    } header: {
                        Text("Security")
                    } footer: {
                        Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
                    }
                    if let extendedInfo = state.extendedInfo {
                        Section("Miscellaneous") {
                            LabeledContent("Identifier", value: extendedInfo.id)
                            LabeledContent("Serial Number", value: extendedInfo.serialNumber)
                            LabeledContent("eSIM", value: extendedInfo.iccid)
                            LabeledContent("Color", value: extendedInfo.color)
                        }
                        .textSelection(.enabled)
                    }
                    Section("Appearance") {
                        ColorPicker("Theme", selection: $accentColor, supportsOpacity: false)
                        #if os(iOS)
                        Button("App Icon") {
                            self.navigationStore.iconChangerPresented = true
                        }
                        .sheet(isPresented: $navigationStore.iconChangerPresented) {
                            IconChangerView()
                        }
                        #endif
                    }
                }
            }
            .refreshable {
                await load()
            }
            .navigationTitle("Settings")
        }
        .overlay {
            if state.subscription == nil, state.isLoading {
                ProgressView()
            }
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
    }
    
    func load() async {
        do {
            do {
                let flag = try await API.shared.featureFlag(name: "visionAccess")
                self.state.isVisionBetaEnabled = flag.bool
            } catch {
                print(error)
            }
            let sub = try await API.shared.subscription()
            withAnimation {
                self.state.subscription = sub
            }
            let extendedInfo = try await API.shared.retrieveDetailedDeviceInfo()
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
}
