//
//  EcoVis_Data_CollectionApp.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/6/25.
//


import SwiftUI
import ClerkSDK

@main
struct EcoVis_Data_CollectionApp: App {
    enum Mode { case object, row }
    
    @State private var selectedMode: Mode? = nil
    private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.loadingState == .notLoaded {
                    ProgressView()
                
                // not signed in yet
                } else if clerk.user == nil {
                    SignUpOrSignInView()
                
                // Signed in, but no mode chosen
                } else if selectedMode == nil {
                    ModeSelectionView(selectedMode: $selectedMode)
                
                // Signed in & mode chosen
                } else {
                    switch selectedMode! {
                    case .object:
                        ContentView(selectedMode: $selectedMode)
                    case .row:
                        RowModeView(selectedMode: $selectedMode)
                    }
                }
            }
            .task {
                clerk.configure(publishableKey: "pk_test_am9pbnQtcGVhY29jay02OC5jbGVyay5hY2NvdW50cy5kZXYk")
                try? await clerk.load()
            }
        }
    }
}













//import SwiftUI
//import ClerkSDK
//
//@main
//struct EcoVis_Data_CollectionApp: App {
//    /// After sign‑in, let the user pick between Object vs Row mode
//    enum Mode { case object, row }
//    
//    /// The shared Clerk client
//    private var clerk = Clerk.shared
//    /// Tracks which mode the user has selected (nil = not selected yet)
//    @State private var selectedMode: Mode? = nil
//
//    var body: some Scene {
//        WindowGroup {
//            ZStack {
//                // 1) Still loading Clerk?
//                if clerk.loadingState == .notLoaded {
//                    ProgressView()
//                
//                // 2) Not signed in yet?
//                } else if clerk.user == nil {
//                    SignUpOrSignInView()
//                
//                // 3) Signed in, but no mode chosen yet
//                } else if selectedMode == nil {
//                    ModeSelectionView(selectedMode: $selectedMode)
//                
//                // 4) Finally: launch the chosen feature
//                } else {
//                    switch selectedMode! {
//                    case .object:
//                        ContentView()
//                    case .row:
//                        RowModeView()
//                    }
//                }
//            }
//            .task {
//                // configure your Clerk publishable key, then load
//                clerk.configure(
//                  publishableKey: "pk_test_am9pbnQtcGVhY29jay02OC5jbGVyay5hY2NvdW50cy5kZXYk"
//                )
//                try? await clerk.load()
//            }
//        }
//    }
//}
