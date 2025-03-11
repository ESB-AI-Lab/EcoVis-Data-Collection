//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//
//

import SwiftUI

struct ContentView: View {
    // Left & right images currently displayed in the UI:
    @State private var leftImage: UIImage? = nil   // The "reference" image
    @State private var rightImage: UIImage? = nil  // The "next" image

    // Arrays storing all captured images:
    @State private var savedLeftImages: [UIImage] = []
    @State private var savedRightImages: [UIImage] = []

    // For camera & region selection
    @State private var isShowingCamera = false
    @State private var isCapturingLeft = true     // Which camera capture are we doing now?
    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear

    // Rectangle selection (in image pixel coords) for the reference (left) image
    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted: Bool = false
    @State private var regionEditing: Bool = true

    // Overlap checker
    let imageOverlapChecker = ImageOverlapChecker()

    // Shows a list of all saved images after "Upload"
    @State private var showSavedImages = false

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(borderColor, lineWidth: 20)

            VStack(spacing: 20) {
                // Updated top message
                Text("Retake reference image each time you have rotated 90° around the object")
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()

                // Two images side by side: reference (left) and next (right)
                HStack {
                    // Reference image with rectangle selection
                    VStack {
                        ZStack {
                            if let leftImage = leftImage {
                                Image(uiImage: leftImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .overlay(
                                        RegionSelectorView(
                                            image: leftImage,
                                            selectedRect: $selectedRegion,
                                            isCompleted: $regionSelectionCompleted,
                                            isEditable: regionEditing
                                        )
                                    )
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Next image
                    VStack {
                        if let rightImage = rightImage {
                            Image(uiImage: rightImage)
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

                // Renamed buttons:
                // "Capture Reference Image" (instead of "Retake Left Image")
                Button("Capture Reference Image") {
                    isCapturingLeft = true
                    showCamera()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

                // "Capture Next Image" (instead of "Capture Right Image")
                Button("Capture Next Image") {
                    isCapturingLeft = false
                    showCamera()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                // "Check Overlap" if both images and region exist
                if leftImage != nil,
                   rightImage != nil,
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

                // "Upload" button
                Button("Upload") {
                    showSavedImages = true
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Feedback message
                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor == .green ? .green : .red)
                        .padding()
                }
            }
            .padding()
        }
        // Show all saved images upon "Upload"
        .sheet(isPresented: $showSavedImages) {
            SavedImagesView(
                leftImages: savedLeftImages,
                rightImages: savedRightImages,
                onReset: resetAll
            )
        }
        // Camera sheet
        .sheet(isPresented: $isShowingCamera) {
            CameraView(image: isCapturingLeft ? $leftImage : $rightImage)
                .onDisappear {
                    if isCapturingLeft {
                        handleNewLeftImage()
                    } else {
                        handleNewRightImage()
                    }
                }
        }
    }

    // MARK: - Camera & Image Handling

    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }

    private func handleNewLeftImage() {
        guard let leftImage = leftImage else { return }
        saveImageLocally(leftImage, isLeft: true)
        regionSelectionCompleted = false
        selectedRegion = nil
        regionEditing = true
        feedbackMessage = "Captured a new REFERENCE image. Draw a region & capture next images!"
        borderColor = .clear
    }

    private func handleNewRightImage() {
        guard let rightImage = rightImage else { return }
        if let leftImg = leftImage,
           let region = selectedRegion,
           regionSelectionCompleted
        {
            let overlapDetected = imageOverlapChecker.checkRegionOverlap(
                image1: leftImg,
                image2: rightImage,
                region: region
            )
            if overlapDetected {
                feedbackMessage = "This next image overlaps with the reference!"
                borderColor = .green
            } else {
                feedbackMessage = "No overlap in the selected region."
                borderColor = .red
            }
        } else {
            feedbackMessage = "Next image captured, but no reference region drawn yet."
            borderColor = .clear
        }
        saveImageLocally(rightImage, isLeft: false)
    }

    // MARK: - Overlap Checking

    private func checkRegionOverlap() {
        guard let leftImg = leftImage,
              let rightImg = rightImage,
              let region = selectedRegion else {
            feedbackMessage = "Missing images or region."
            return
        }
        let overlapDetected = imageOverlapChecker.checkRegionOverlap(
            image1: leftImg,
            image2: rightImg,
            region: region
        )
        if overlapDetected {
            feedbackMessage = "The selected region overlaps!"
            borderColor = .green
        } else {
            feedbackMessage = "No sufficient overlap in the selected region."
            borderColor = .red
        }
    }

    // MARK: - Saving & Reset

    private func saveImageLocally(_ image: UIImage, isLeft: Bool) {
        if isLeft {
            savedLeftImages.append(image)
        } else {
            savedRightImages.append(image)
        }
        // In a real app, we'd use FileManager to write data to disk;
        // for now, just store them in memory arrays.
    }

    private func resetAll() {
        leftImage = nil
        rightImage = nil
        savedLeftImages.removeAll()
        savedRightImages.removeAll()
        selectedRegion = nil
        regionSelectionCompleted = false
        regionEditing = true
        feedbackMessage = ""
        borderColor = .clear
    }
}




//import SwiftUI
//
//struct ContentView: View {
//    @State private var firstImage: UIImage? = nil
//    @State private var secondImage: UIImage? = nil
//    @State private var isShowingCamera = false
//    @State private var isCapturingFirstImage = true
//    @State private var feedbackMessage = ""
//    @State private var borderColor: Color = .clear
//    
//    // State variables for region selection on the first image.
//    // selectedRegion will be in the image’s pixel space after conversion.
//    @State private var selectedRegion: CGRect? = nil
//    @State private var regionSelectionCompleted: Bool = false
//    @State private var regionEditing: Bool = true
//
//    let imageOverlapChecker = ImageOverlapChecker()
//
//    var body: some View {
//        ZStack {
//            // Background border for visual feedback (green/red) after checking overlap
//            Rectangle()
//                .stroke(borderColor, lineWidth: 20)
//            
//            VStack(spacing: 20) {
//                // Two images side-by-side
//                HStack {
//                    // First image with an overlay for drawing a rectangle
//                    VStack {
//                        if let firstImage = firstImage {
//                            ZStack {
//                                Image(uiImage: firstImage)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 150)
//                                    .overlay(
//                                        // RegionSelectorView draws a rectangle and converts coords
//                                        RegionSelectorView(
//                                            image: firstImage,
//                                            selectedRect: $selectedRegion,
//                                            isCompleted: $regionSelectionCompleted,
//                                            isEditable: regionEditing
//                                        )
//                                    )
//                            }
//                        } else {
//                            Image(systemName: "photo")
//                                .resizable()
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    
//                    // Second image
//                    VStack {
//                        if let secondImage = secondImage {
//                            Image(uiImage: secondImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 150)
//                        } else {
//                            Image(systemName: "photo")
//                                .resizable()
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//                
//                // "Redraw Region" button appears only after region is drawn
//                if firstImage != nil, regionSelectionCompleted {
//                    Button("Redraw Region") {
//                        regionEditing = true
//                        regionSelectionCompleted = false
//                        selectedRegion = nil
//                    }
//                    .padding()
//                    .background(Color.purple)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//                
//                // If we haven't captured both images yet, show "Capture" button
//                if firstImage == nil || secondImage == nil {
//                    Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second Image") {
//                        showCamera()
//                    }
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//                
//                // If both images exist, show Retake buttons
//                if firstImage != nil && secondImage != nil {
//                    HStack {
//                        Button("Retake First") {
//                            isCapturingFirstImage = true
//                            // Reset region
//                            regionSelectionCompleted = false
//                            selectedRegion = nil
//                            regionEditing = true
//                            showCamera()
//                        }
//                        .padding()
//                        .background(Color.orange)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//
//                        Button("Retake Second") {
//                            isCapturingFirstImage = false
//                            showCamera()
//                        }
//                        .padding()
//                        .background(Color.orange)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                    }
//                }
//                
//                // "Check Overlap" available if both images exist and region is drawn
//                if firstImage != nil,
//                   secondImage != nil,
//                   regionSelectionCompleted,
//                   selectedRegion != nil
//                {
//                    Button("Check Overlap") {
//                        checkRegionOverlap()
//                    }
//                    .padding()
//                    .background(Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//                
//                // Feedback message (green or red)
//                if !feedbackMessage.isEmpty {
//                    Text(feedbackMessage)
//                        .foregroundColor(borderColor == .green ? .green : .red)
//                        .padding()
//                }
//            }
//            .padding()
//        }
//        // Present camera
//        .sheet(isPresented: $isShowingCamera) {
//            CameraView(image: isCapturingFirstImage ? $firstImage : $secondImage)
//                .onDisappear {
//                    // After capturing first image, reset region selection
//                    if isCapturingFirstImage, firstImage != nil {
//                        regionSelectionCompleted = false
//                        selectedRegion = nil
//                        regionEditing = true
//                    }
//                    // Once first image is captured, switch to second
//                    if firstImage != nil && isCapturingFirstImage {
//                        isCapturingFirstImage = false
//                    }
//                }
//        }
//    }
//    
//    private func showCamera() {
//        isShowingCamera = false
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            isShowingCamera = true
//        }
//    }
//    
//    /// Compares the user-drawn region between both images
//    func checkRegionOverlap() {
//        guard let firstImage = firstImage,
//              let secondImage = secondImage,
//              let region = selectedRegion else {
//            return
//        }
//        
//        let overlapDetected = imageOverlapChecker.checkRegionOverlap(image1: firstImage,
//                                                                     image2: secondImage,
//                                                                     region: region)
//        if overlapDetected {
//            feedbackMessage = "The selected region overlaps!"
//            borderColor = .green
//        } else {
//            feedbackMessage = "No sufficient overlap in the selected region."
//            borderColor = .red
//        }
//    }
//}
