import SwiftUI

struct IconItem: Identifiable {
    var id: UUID
    var title: String
    var iconName: String
    var imageName: String
}

struct IconChangerView: View {
    @Environment(\.dismiss) 
    private var dismiss
    
    var icons = [
        IconItem(id: UUID(), title: "Classic", iconName: "", imageName: "AppIconPreview"),
        IconItem(id: UUID(), title: "Stargaze", iconName: "StarIcon", imageName: "StarIconPreview"),
        IconItem(id: UUID(), title: "Ai Pin", iconName: "DeviceIcon", imageName: "DeviceIconPreview"),
        IconItem(id: UUID(), title: ".Center", iconName: "LogoIconDark", imageName: "LogoIconDarkPreview"),
        IconItem(id: UUID(), title: "Sensors", iconName: "SensorsIcon", imageName: "SensorsIconPreview"),
        IconItem(id: UUID(), title: "Ai Pin Dark", iconName: "TextLogoDark", imageName: "TextLogoDarkPreview"),
        IconItem(id: UUID(), title: "Ai Pin Light", iconName: "TextLogoLight", imageName: "TextLogoLightPreview")]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                ForEach(icons, id: \.self.id) { icon in
                    Button {
                        changeAppIcon(to: icon.iconName)
                    } label: {
                        VStack(alignment: .center, spacing: 8) {
                            Image(icon.imageName)
                                .resizable()
                                .frame(width: 130, height: 130)
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
                            Text(icon.title)
                                .font(Font.system(.title2))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding([.leading, .trailing])
        }
        .scrollIndicators(.hidden)
    }
    
    
    private func changeAppIcon(to iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName != "" ? iconName : nil) { error in
            if let error = error {
                print("Error setting alternate icon \(error.localizedDescription)")
            }

        }
        
        dismiss()
    }
}

#Preview {
    IconChangerView()
}
