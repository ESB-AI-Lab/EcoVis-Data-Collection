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
    @State private var isCapturingFirstImage = true
    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear

    let imageOverlapChecker = ImageOverlapChecker()

    var body: some View {
        ZStack {
            // Apply the border as a background
            Rectangle()
                .stroke(borderColor, lineWidth: 20) // Draw the border
            
            VStack(spacing: 20) {
                // Display the captured images or placeholders
                HStack {
                    VStack {
                        // First image
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
                    }
                    
                    VStack {
                        // Second image
                        if let secondImage = secondImage {
                            Image(uiImage: secondImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Button to capture images (only show if both images are not captured yet)
                if firstImage == nil || secondImage == nil {
                    Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second Image") {
                        showCamera()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Show retake buttons only after both images are taken
                if firstImage != nil && secondImage != nil {
                    HStack {
                        Button("Retake") {
                            isCapturingFirstImage = true
                            showCamera()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Retake") {
                            isCapturingFirstImage = false
                            showCamera()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                // Check overlap if both images are captured
                if firstImage != nil && secondImage != nil {
                    Button("Check Overlap") {
                        checkImageOverlap()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Show feedback message
                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor == .green ? .green : .red)
                        .padding()
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraView(image: isCapturingFirstImage ? $firstImage : $secondImage)
                .onDisappear {
                    // Ensure state updates correctly when an image is captured
                    if firstImage != nil && isCapturingFirstImage {
                        isCapturingFirstImage = false
                    }
                }
        }
    }
    
    /// Function to show the camera properly
    private func showCamera() {
        isShowingCamera = false  // Reset to ensure the sheet updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true  // Reopen camera with a small delay
        }
    }

    func checkImageOverlap() {
        guard let firstImage = firstImage, let secondImage = secondImage else { return }

        let overlapDetected = imageOverlapChecker.checkImageOverlap(firstImage, secondImage)
        if overlapDetected {
            feedbackMessage = "The images overlap!"
            borderColor = .green
        } else {
            feedbackMessage = "No overlap detected."
            borderColor = .red
        }
    }
}
