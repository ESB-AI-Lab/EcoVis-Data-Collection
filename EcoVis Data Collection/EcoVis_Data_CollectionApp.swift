//
//  EcoVis_Data_CollectionApp.swift
//  EcoVis Data Collection
//
//  Created by Kanishka on 9/25/24.
//

import SwiftUI
import ClerkSDK

@main
struct EcoVis_Data_CollectionApp: App {
    private var clerk = Clerk.shared
    var body: some Scene {
        WindowGroup {
            ZStack {
                    if clerk.loadingState == .notLoaded {
                      ProgressView()
                    } else {
                      ContentView()
                    }
                  }
                  .task {
                    clerk.configure(publishableKey: "pk_test_am9pbnQtcGVhY29jay02OC5jbGVyay5hY2NvdW50cy5kZXYk")
                    try? await clerk.load()
                  }
        }
    }
}
