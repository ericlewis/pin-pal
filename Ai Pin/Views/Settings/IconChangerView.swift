import SwiftUI

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
    var selectedIcon: IconDescription {
        switch self {
        case .initial: return IconDescription(title: "Sensors", iconName: "", imageName: "AppIconPreview")
        case .deviceIcon: return IconDescription(title: "Ai Pin", iconName: "DeviceIcon", imageName: "DeviceIconPreview")
        }
    }
}

struct IconChangerView: View {
    @Environment(\.dismiss) 
    private var dismiss
    
    @State
    private var isLoading = false
    
    @State
    private var selectedIcon: Icon = .initial

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $selectedIcon) {
                    ForEach(Icon.allCases) { icon in
                        HStack(spacing: 15) {
                            Image(icon.selectedIcon.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            
                            Text(icon.selectedIcon.title)
                        }
                    }
                }
                .pickerStyle(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isLoading = true
                        changeAppIcon(to: selectedIcon)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Change App Icon")
        }
        .disabled(isLoading)
        .interactiveDismissDisabled(isLoading)
        .onAppear() {
            let result = loadAppIconName()
            selectedIcon = result
        }
    }
    
    private func changeAppIcon(to iconName: Icon) {
        UIApplication.shared.setAlternateIconName(iconName.selectedIcon.iconName != "" ? iconName.selectedIcon.iconName : nil) { error in
            if let error = error {
                print("Error setting alternate icon \(error.localizedDescription)")
                return
            }
        }
        
        UserDefaults.standard.set(iconName.rawValue, forKey: Constants.UI_CUSTOM_APP_ICON_V1)
    }
    
    func loadAppIconName() -> Icon {
        guard let iconRawValue = UserDefaults.standard.string(forKey: Constants.UI_CUSTOM_APP_ICON_V1),
              let iconCase = Icon(rawValue: iconRawValue) else {
            return .initial
        }

        return iconCase
    }
}

#Preview {
    IconChangerView()
}
