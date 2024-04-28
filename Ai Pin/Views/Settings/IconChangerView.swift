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
    
    @State
    private var isLoading = false
    
    var icons = [
        IconItem(id: UUID(), title: "Sensors", iconName: "", imageName: "AppIconPreview"),
        IconItem(id: UUID(), title: "Ai Pin", iconName: "DeviceIcon", imageName: "DeviceIconPreview")]
    
    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Change App Icon")
        }
        .disabled(isLoading)
        .interactiveDismissDisabled(isLoading)
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
