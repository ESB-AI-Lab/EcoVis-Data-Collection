//
//  EcoVis_Data_CollectionApp.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//

import SwiftUI

@main
struct EcoVis_Data_CollectionApp: App {
    enum Mode { case object, row }
        @State private var selectedMode: Mode? = nil

        var body: some Scene {
            WindowGroup {
                if let mode = selectedMode {
                    switch mode {
                    case .object:
                        ContentView()
                    case .row:
                        RowModeView()
                    }
                } else {
                    ModeSelectionView(selectedMode: $selectedMode)
                }
            }
        }
    }
