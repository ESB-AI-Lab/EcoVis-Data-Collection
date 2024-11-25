//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    @State private var firstImage: UIImage? = nil
    @State private var secondImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var borderColor: Color = .clear
    @State private var isCapturingFirstImage = true
    let imageQualityChecker = ImageQualityChecker()
    //Body contains UI structure
    var body: some View {
        ZStack {
            // Apply the border as a background
            Rectangle()
                .stroke(borderColor, lineWidth: 20) // Draw the border
        
            VStack {
                // Display the captured image or a placeholder if no image is available
                HStack {
                    //Capture first image
                    if let firstImage = firstImage {
                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                        
                    } 
                    else {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    //Capture Second image
                    if let secondImage = secondImage {
                        Image(uiImage: secondImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
                
                // Button to show the camera
                Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second image") {
                    isShowingCamera = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .sheet(isPresented: $isShowingCamera) {
                    CameraView(image: isCapturingFirstImage ? $firstImage : $secondImage) // This shows the camera
                }
                
                if firstImage != nil && secondImage != nil {
                    Button("Check Quality") {
                        checkImageQuality()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                
            }
        }
        .padding()
    }
    
    func toggleBorder(isImageClear: Bool) {
        borderColor = isImageClear ? .green : .red
    }
    
    func checkImageQuality() {
        guard let first = firstImage, let second = secondImage else { return }
        
        let isBrightnessConsistent = imageQualityChecker.consistentBrightness(image1: first, image2: second)
        let isFirstClear = imageQualityChecker.performBlurrinessCheck(for: first)
        let isSecondClear = imageQualityChecker.performBlurrinessCheck(for: second)
        
        if isBrightnessConsistent && isFirstClear && isSecondClear {
            toggleBorder(isImageClear: true)
        } else {
            toggleBorder(isImageClear: false)
        }
    }
    
    func createOverlay() {
        guard let first = firstImage, let second = secondImage else { return }
    }
}

#Preview {
    ContentView()
}

