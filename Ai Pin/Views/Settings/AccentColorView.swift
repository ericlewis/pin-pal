import SwiftUI

struct AccentColorView: View {
    @Environment(ColorStore.self)
    private var colorStore: ColorStore
    
    @State
    private var notes: [Note] = [
        Note(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco", title: "Lorem Ipsum"),
        Note(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco", title: "Lorem Ipsum"),
        Note(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco", title: "Lorem Ipsum")
    ]
    
    @State 
    private var accentColor = Color.blue
    
    @State
    private var originalColor = Color.blue
    
    @State
    private var triggerSaveHatic = false
    
    @State
    private var isLoading = false
    
    @Environment(\.dismiss) 
    private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    List {
                        ForEach(notes, id: \.id) { note in
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(note.title)
                                        .foregroundStyle(accentColor)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(note.text)
                                }
                                
                                Text("24/4/2024, 9:01 p.m.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                ColorPicker("", selection: $accentColor, supportsOpacity: true)
                    .labelsHidden()
                    .foregroundStyle(.foreground)
                    .padding()
                    .scaleEffect(CGSize(width: 2.5, height: 2.5))
                    .padding([.bottom])
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            isLoading = true
                            triggerSaveHatic.toggle()
                            colorStore.setColor(color: accentColor)
                            dismiss()
                        }
                        .tint(accentColor)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if (originalColor == accentColor) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .tint(accentColor)
                    } else {
                        Button("Reset") {
                            colorStore.setColor(color: originalColor)
                            accentColor = originalColor
                        }
                        .tint(accentColor)
                    }
                }
            }
            .navigationTitle("Edit Accent Color")
        }
        .disabled(isLoading)
        .interactiveDismissDisabled(isLoading)
        .sensoryFeedback(.success, trigger: triggerSaveHatic)
        .onAppear() {
            accentColor = colorStore.accentColor
            originalColor = colorStore.accentColor
        }
    }
}

#Preview {
    AccentColorView()
}
