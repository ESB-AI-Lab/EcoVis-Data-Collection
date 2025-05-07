//
//  ModeSelectionView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: EcoVis_Data_CollectionApp.Mode?

    var body: some View {
        VStack(spacing: 40) {
            Text("Select a mode")
                .font(.largeTitle)
                .bold()

            Button("Row Mode") {
                selectedMode = .row
            }
            .modeButtonStyle(color: .blue)

            Button("Object Mode") {
                selectedMode = .object
            }
            .modeButtonStyle(color: .green)
        }
        .padding()
    }
}

private extension View {
    func modeButtonStyle(color: Color) -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
