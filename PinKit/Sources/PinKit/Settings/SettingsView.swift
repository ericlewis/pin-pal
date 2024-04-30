import SwiftUI
import OSLog

struct SettingsView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(SettingsRepository.self)
    private var repository
    
    @AppStorage(Constants.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constants.defaultAppAccentColor
    
    @AppStorage(Constants.UI_CUSTOM_APP_ICON_V1)
    private var selectedIcon: Icon = Icon.initial
    
    @Environment(\.openURL)
    private var openURL
    
    @State
    private var deleteAllNotesConfirmationPresented = false
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        @Bindable var repository = repository
        NavigationStack {
            Form {
                Section("Device") {
                    LabeledContent("Account Number", value: repository.subscription?.accountNumber ?? "AAAAAAAAAAAAAAA")
                    LabeledContent("Phone Number", value: repository.subscription?.phoneNumber ?? "1111111111")
                    LabeledContent("Status", value: repository.subscription?.status ?? "ACTIVE")
                    LabeledContent("Plan", value: repository.subscription?.planType ?? "DEFAULT_PLAN")
                    LabeledContent("Monthly Price") {
                        if let subscription = repository.subscription {
                            Text("$\(subscription.planPrice / 100)")
                        } else {
                            Text(repository.subscription?.planType ?? "$24")
                        }
                    }
                }
                .labeledContentStyle(AsyncValueLabelContentStyle(isLoading: repository.subscription == nil))
                Section {
                    Toggle(isOn: $repository.isVisionBetaEnabled) {
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
                    .disabled(repository.isLoading)
                    Button("Add Wi-Fi Network") {
                        self.navigationStore.isWifiCodeGeneratorPresented = true
                    }
                    .sheet(isPresented: $navigationStore.isWifiCodeGeneratorPresented) {
                        WifiQRCodeGenView()
                    }
                    if canDevicePlaceCalls() {
                        Button("Call my device") {
                            if let number = repository.subscription?.phoneNumber, let url = URL(string: "tel://\(number)") {
                                openURL(url.appending(path: number))
                            }
                        }
                        .disabled(repository.subscription == nil)
                    }
                    Toggle("Block my device", isOn: $repository.isDeviceLost)
                        .disabled(repository.isLoading)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Marking your Ai Pin as lost or stolen keeps your .Center data safe and remotely locks your Pin. If your Pin is successfully unlocked while in this state, access to any of your .Center data will still be blocked. Once you recover your Pin, remember to disable this setting.")
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
                Section("Danger Zone") {
                    Button("Delete all notes", role: .destructive) {
                        self.deleteAllNotesConfirmationPresented = true
                    }
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
        } label: {
            configuration.label
        }
    }
}

#Preview {
    SettingsView()
        .environment(HumaneCenterService.live())
}
