//
//  EcoVis_Data_CollectionApp.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/6/25.
//

import SwiftUI
import ClerkSDK
import FirebaseCore      // ← add

/// 1) Create a minimal UIApplicationDelegate to configure Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()  // ← configure Firebase as soon as the app launches
    return true
  }
}

@main
struct EcoVis_Data_CollectionApp: App {
    // 2) Hook your AppDelegate in
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    enum Mode { case object, row }
    @State private var selectedMode: Mode? = nil
    private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.loadingState == .notLoaded {
                    ProgressView()
                } else if clerk.user == nil {
                    SignUpOrSignInView()
                } else if selectedMode == nil {
                    ModeSelectionView(selectedMode: $selectedMode)
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
                clerk.configure(
                  publishableKey: "pk_test_am9pbnQtcGVhY29jay02OC5jbGVyay5hY2NvdW50cy5kZXYk"
                )
                try? await clerk.load()
            }
        }
    }
}



