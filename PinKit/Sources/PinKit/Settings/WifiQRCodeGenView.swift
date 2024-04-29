import SwiftUI
import CoreImage.CIFilterBuiltins

struct WifiQRCodeGenView: View {
    
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
    }
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var state = ViewState()
    
    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Name") {
                    TextField("Network Name", text: $state.name)
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
                    NavigationLink("Next") {
                        Image(uiImage: generateQRCode(from: "WIFI:S:\(state.name);T:\(state.securityType.rawValue);P:\(state.password);H:\(state.isHidden ? "true" : "false");;"))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .navigationTitle("Scan QR Code")
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        dismiss()
                                    }
                                }
                            }
                    }
                    .disabled(state.name.isEmpty || state.password.isEmpty)
                }
            }
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
