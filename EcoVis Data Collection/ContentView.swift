//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kanishka on 9/25/24.
//

import SwiftUI
import ClerkSDK

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    private var motionManager = MotionManager()
    private var clerk = Clerk.shared
    
    @State private var firstImage: UIImage? = nil
    @State private var secondImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var borderColor: Color = .clear
    @State private var isCapturingFirstImage = true
    @State private var feedbackMessage = ""
    let imageQualityChecker = ImageQualityChecker()

    var body: some View {
        VStack {
            if let user = clerk.user {
                // Show main app content when the user is signed in
                ZStack {
                    // Apply the border as a background
                    Rectangle()
                        .stroke(borderColor, lineWidth: 20) // Draw the border
                
                    VStack {
                        // Display the captured image or a placeholder if no image is available
                        HStack {
                            // Capture first image
                            if let firstImage = firstImage {
                                Image(uiImage: firstImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            // Capture Second image
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
                        if !feedbackMessage.isEmpty {
                            Text(feedbackMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        Button("Sign Out") {
                            Task { try? await clerk.signOut() }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                // Show SignUpOrSignInView when the user is signed out
                SignUpOrSignInView()
            }
        }
    }
    
    func toggleBorder(isImageClear: Bool) {
        borderColor = isImageClear ? .green : .red
    }
    
    func checkImageQuality() {
        guard let first = firstImage, let second = secondImage else { return }
        
        let brightnessCheckResult = imageQualityChecker.consistentBrightness(image1: first, image2: second)
        let isFirstClear = imageQualityChecker.performBlurrinessCheck(for: first)
        let isSecondClear = imageQualityChecker.performBlurrinessCheck(for: second)
        let firstWhiteBalance = imageQualityChecker.checkWhiteBalance(for: first)
        let secondWhiteBalance = imageQualityChecker.checkWhiteBalance(for: second)
        
        if brightnessCheckResult.isConsistent && brightnessCheckResult.isExposureGood1 && brightnessCheckResult.isExposureGood2 && isFirstClear && isSecondClear && firstWhiteBalance && secondWhiteBalance{
            toggleBorder(isImageClear: true)
        } else {
            toggleBorder(isImageClear: false)
            var reasons: [String] = []
            if !brightnessCheckResult.isConsistent {
                reasons.append("Brightness is inconsistent between the two images.")
            }
            if !brightnessCheckResult.isExposureGood1 {
                reasons.append("First image has poor exposure")
            }
            if !brightnessCheckResult.isExposureGood2 {
                reasons.append("Second image has poor exposure")
            }
            if !isFirstClear {
                reasons.append("The first image is blurry.")
            }
            if !isSecondClear {
                reasons.append("The second image is blurry.")
            }
            if !firstWhiteBalance {
                reasons.append("First image has poor white balance")
            }
            if !secondWhiteBalance {
                reasons.append("Second image has poor white balance")
            }
            
            feedbackMessage = "Quality check failed: " + reasons.joined(separator: " ")
        }
    }
    
    func createOverlay() {
        guard let first = firstImage, let second = secondImage else { return }
    }
}


#Preview {
    ContentView()
}
