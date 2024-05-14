import SwiftUI
import CoreImage.CIFilterBuiltins

struct WifiQRCodeGenView: View {
    
    enum Field {
        case name
        case password
    }
    
    enum WifiSecurityType: String {
        case wpa = "WPA"
        case wep = "WEP"
        case none = "nopass"
    }
    
    struct ViewState {
        var name = ""
        var password = ""
        var securityType: WifiSecurityType = .wpa
        var isHidden = false
        var isActive = false
    }
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var state = ViewState()
    
    @FocusState
    private var focus: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Name") {
                    TextField("Network Name", text: $state.name)
                        .focused($focus, equals: Field.name)
                        .submitLabel(state.securityType == .none ? .done : .next)
                        .onSubmit {
                            if state.securityType == .none {
                                state.isActive = true
                            } else {
                                focus = .password
                            }
                        }
                }
                Section {
                    Picker("Security Type", selection: $state.securityType) {
                        Text("WPA/WPA2/WPA3").tag(WifiSecurityType.wpa)
                        Text("WEP").tag(WifiSecurityType.wep)
                        Text("None").tag(WifiSecurityType.none)
                    }
                    if state.securityType != .none {
                        LabeledContent("Password") {
                            SecureField("", text: $state.password)
                                .focused($focus, equals: Field.password)
                                .submitLabel(.done)
                                .onSubmit {
                                    state.isActive = true
                                }
                        }
                    }
                }
                Toggle("This network is hidden", isOn: $state.isHidden)
            }
            .navigationTitle("Add Wi-Fi Network")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink("Next", isActive: $state.isActive) {
                        List {
                            Image(uiImage: generateQRCode(from: "WIFI:S:\(state.name);T:\(state.securityType.rawValue);P:\(state.password);H:\(state.isHidden ? "true" : "false");;"))
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(1, contentMode: .fit)
                                .listRowInsets(.init())
                            Section {
                                Group {
                                    Label("Tap and hold the touchpad on your Ai Pin and say “turn on WiFi”", systemImage: "1.circle")
                                    Label("Raise your palm to activate the Laser Ink display and select “quick setup” and then “scan code”", systemImage: "2.circle")
                                    Label("Position the QR code in front of your Ai Pin to begin scanning. If successful, you should hear a chime.", systemImage: "3.circle")
                                }
                                .font(.headline)
                            } header: {
                                Text("How to scan")
                            } footer: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Having trouble connecting?")
                                        .bold()
                                    Text("If you’re having trouble connecting to WiFi, you may need to re-enter your credentials. Confirm your network credentials and password are correct and regenerate a QR code. If you’re still having trouble, you can  reach out to support.")
                                }
                            }
                        }
                        .navigationTitle("Scan QR Code")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(state.name.isEmpty || (state.securityType != .none && state.password.isEmpty))
                }
            }
        }
        .onAppear {
            self.focus = .name
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

#Preview {
    WifiQRCodeGenView()
}
