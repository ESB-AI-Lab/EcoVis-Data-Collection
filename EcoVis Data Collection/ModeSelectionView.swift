//
//  ModeSelectionView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//
//
//

//  ModeSelectionView.swift
//  EcoVis Data Collection
//
//  Updated 2025-06 to center content vertically.

import SwiftUI
import ClerkSDK

struct ModeSelectionView: View {
    @Binding var selectedMode: EcoVis_Data_CollectionApp.Mode?
    @State private var showHistory = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()  // Push content toward center

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

                    Button("History") {
                        showHistory = true
                    }
                    .modeButtonStyle(color: .orange)

                    Button("Log Out") {
                        Task {
                            try? await Clerk.shared.signOut()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                
                Spacer()  // Push content toward center
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: HistoryView(),
                    isActive: $showHistory,
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
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

