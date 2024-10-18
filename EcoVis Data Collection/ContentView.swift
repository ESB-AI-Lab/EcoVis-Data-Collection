//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    @State private var image: UIImage? = nil
    @State private var isShowingCamera = false
    
    var body: some View {
        VStack {
            // Display the captured image or a placeholder if no image is available
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Image(systemName: "camera")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            // Button to show the camera
            Button("Take Picture") {
                isShowingCamera = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .sheet(isPresented: $isShowingCamera) {
                CameraView(image: $image) // This shows the camera
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

