//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//
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

                // Button to capture the images
                Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second Image") {
                    isShowingCamera = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .sheet(isPresented: $isShowingCamera) {
                    CameraView(image: isCapturingFirstImage ? $firstImage : $secondImage)
                        .onDisappear {
                            // Move to the next step after capturing the first image
                            if firstImage != nil && isCapturingFirstImage {
                                isCapturingFirstImage = false
                            }
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
