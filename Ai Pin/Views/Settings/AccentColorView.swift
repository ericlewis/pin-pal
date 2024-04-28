//
//  AccentColorView.swift
//  Ai Pin
//
//  Created by Diego Gutierrez on 27/04/24.
//

import SwiftUI

struct AccentColorView: View {
    @Environment(ColorStore.self)
    private var colorStore: ColorStore
    
    @State 
    private var accentColor = Color.blue
    
    @State
    private var originalColor = Color.blue
    
    @State
    private var triggerSave = false
    
    @Environment(\.dismiss) 
    private var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("This is an example title")
                .foregroundStyle(accentColor)
                .padding([.bottom], 5)
                .bold()
                .font(Font.system(size: 20))
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum sem lacus, scelerisque ut ultrices in, aliquam ut massa. Vestibulum sed iaculis diam. In pulvinar felis nibh, ultrices bibendum tellus elementum ut. Ut non turpis feugiat, molestie justo sed.")
                .foregroundStyle(.foreground)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
        .padding(13)
        .padding([.top], 20)
        .onAppear() {
            let tempColor = colorStore.loadColor()
            accentColor = tempColor
            originalColor = tempColor
        }
        
        Spacer()
        
        ColorPicker("", selection: $accentColor, supportsOpacity: true)
            .labelsHidden()
            .foregroundStyle(.foreground)
            .padding()
            .scaleEffect(CGSize(width: 2.5, height: 2.5))
            .padding([.bottom])
        
        HStack(spacing: 8) {
            Button {
                triggerSave.toggle()
                colorStore.setColor(color: accentColor)
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Text("Save")
                        .bold()
                    Image(systemName: "checkmark")
                }
            }
            .foregroundStyle(.white)
            .padding()
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
            .sensoryFeedback(.selection, trigger: triggerSave)
            
            if (originalColor != accentColor) {
                Button {
                    colorStore.setColor(color: originalColor)
                    accentColor = originalColor
                } label: {
                    HStack(spacing: 5) {
                        Text("Reset")
                            .bold()
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                .foregroundStyle(.black)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15.0))
            }
        }
        .padding([.bottom], 20)
    }
}

#Preview {
    AccentColorView()
}
