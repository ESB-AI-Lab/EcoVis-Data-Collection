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
    @State private var borderColor: Color = .clear
    let imageQualityChecker = ImageQualityChecker()
    //Body contains UI structure
    var body: some View {
        ZStack {
            // Apply the border as a background
            Rectangle()
                .stroke(borderColor, lineWidth: 20) // Draw the border
                 
            
            
            VStack {
                // Display the captured image or a placeholder if no image is available
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        //Call image quality check
                        .onChange(of: image) { newImage in
                            checkImageQuality(image: newImage) // Check quality when the image changes
                        }
                    
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
        }
        .padding()
    }
    
    func toggleBorder(isImageClear: Bool) {
        borderColor = isImageClear ? .green : .red
    }
    
    func checkImageQuality(image: UIImage) {
        let isImageClear = imageQualityChecker.performBlurrinessCheck(for: image)
        toggleBorder(isImageClear: isImageClear)
    }
}

#Preview {
    ContentView()
}

