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
    
    // State variables for region selection on the first image.
    // selectedRegion will be in the image’s pixel space after conversion.
    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted: Bool = false
    @State private var regionEditing: Bool = true

    let imageOverlapChecker = ImageOverlapChecker()

    var body: some View {
        ZStack {
            // Background border for visual feedback (green/red) after checking overlap
            Rectangle()
                .stroke(borderColor, lineWidth: 20)
            
            VStack(spacing: 20) {
                // Two images side-by-side
                HStack {
                    // First image with an overlay for drawing a rectangle
                    VStack {
                        if let firstImage = firstImage {
                            ZStack {
                                Image(uiImage: firstImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .overlay(
                                        // RegionSelectorView draws a rectangle and converts coords
                                        RegionSelectorView(
                                            image: firstImage,
                                            selectedRect: $selectedRegion,
                                            isCompleted: $regionSelectionCompleted,
                                            isEditable: regionEditing
                                        )
                                    )
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Second image
                    VStack {
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
                
                // "Redraw Region" button appears only after region is drawn
                if firstImage != nil, regionSelectionCompleted {
                    Button("Redraw Region") {
                        regionEditing = true
                        regionSelectionCompleted = false
                        selectedRegion = nil
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // If we haven't captured both images yet, show "Capture" button
                if firstImage == nil || secondImage == nil {
                    Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second Image") {
                        showCamera()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // If both images exist, show Retake buttons
                if firstImage != nil && secondImage != nil {
                    HStack {
                        Button("Retake First") {
                            isCapturingFirstImage = true
                            // Reset region
                            regionSelectionCompleted = false
                            selectedRegion = nil
                            regionEditing = true
                            showCamera()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Retake Second") {
                            isCapturingFirstImage = false
                            showCamera()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // "Check Overlap" available if both images exist and region is drawn
                if firstImage != nil,
                   secondImage != nil,
                   regionSelectionCompleted,
                   selectedRegion != nil
                {
                    Button("Check Overlap") {
                        checkRegionOverlap()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Feedback message (green or red)
                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor == .green ? .green : .red)
                        .padding()
                }
            }
            .padding()
        }
        // Present camera
        .sheet(isPresented: $isShowingCamera) {
            CameraView(image: isCapturingFirstImage ? $firstImage : $secondImage)
                .onDisappear {
                    // After capturing first image, reset region selection
                    if isCapturingFirstImage, firstImage != nil {
                        regionSelectionCompleted = false
                        selectedRegion = nil
                        regionEditing = true
                    }
                    // Once first image is captured, switch to second
                    if firstImage != nil && isCapturingFirstImage {
                        isCapturingFirstImage = false
                    }
                }
        }
    }
    
    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }
    
    /// Compares the user-drawn region between both images
    func checkRegionOverlap() {
        guard let firstImage = firstImage,
              let secondImage = secondImage,
              let region = selectedRegion else {
            return
        }
        
        let overlapDetected = imageOverlapChecker.checkRegionOverlap(image1: firstImage,
                                                                     image2: secondImage,
                                                                     region: region)
        if overlapDetected {
            feedbackMessage = "The selected region overlaps!"
            borderColor = .green
        } else {
            feedbackMessage = "No sufficient overlap in the selected region."
            borderColor = .red
        }
    }
}
