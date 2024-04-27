//
//  AccentColorView.swift
//  Ai Pin
//
//  Created by Diego Gutierrez on 27/04/24.
//

import SwiftUI

struct AccentColorView: View {
    var body: some View {
        VStack {
            Text("Contrary to popular belief, Lorem Ipsum is not simply random text.")
                .foregroundStyle(.blue)
            Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries")
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    AccentColorView()
}
