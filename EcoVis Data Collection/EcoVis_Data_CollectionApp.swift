//
//  EcoVis_Data_CollectionApp.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/6/25.
//

import SwiftUI
import FirebaseAuth
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    enum Mode { case object, row }
    @State private var selectedMode: Mode? = nil
    @State private var user: User? = Auth.auth().currentUser

    var body: some Scene {
        WindowGroup {
            ZStack {
                if user == nil {
                    GoogleSignInView()
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
            .onAppear {
                Auth.auth().addStateDidChangeListener { _, currentUser in
                    user = currentUser
                }
            }
        }
    }
}



