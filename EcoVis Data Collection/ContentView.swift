//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    // Left & right images currently displayed in the UI:
    @State private var leftImage: UIImage? = nil   // The reference image
    @State private var rightImage: UIImage? = nil  // The next image

    // Arrays storing all captured images:
    @State private var savedLeftImages: [UIImage] = []
    @State private var savedRightImages: [UIImage] = []

    // For camera & region selection
    @State private var isShowingCamera = false
    @State private var isCapturingLeft = true
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
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Retake reference image each time you have rotated 90° around the object")
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()

                HStack {
                    // Reference
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

                    // Next
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

                Button("Capture Reference Image") {
                    isCapturingLeft = true
                    showCamera()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Capture Next Image") {
                    isCapturingLeft = false
                    showCamera()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

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

                Button("Upload") {
                    showSavedImages = true
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)

                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor == .green ? .green : .red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Object Mode")
        .sheet(isPresented: $showSavedImages) {
            SavedImagesView(
                leftImages: savedLeftImages,
                rightImages: savedRightImages,
                onReset: resetAll
            )
        }
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

    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }

    private func handleNewLeftImage() {
        guard let img = leftImage else { return }
        savedLeftImages.append(img)
        regionSelectionCompleted = false
        selectedRegion = nil
        regionEditing = true
        feedbackMessage = "Captured a new REFERENCE image. Draw a region & capture next images!"
        borderColor = .clear
    }

    private func handleNewRightImage() {
        guard let img = rightImage else { return }
        if let ref = leftImage,
           let region = selectedRegion,
           regionSelectionCompleted
        {
            let ok = imageOverlapChecker.checkRegionOverlap(
                image1: ref,
                image2: img,
                region: region
            )
            feedbackMessage = ok ? "Overlap Detected" : "No overlap"
            borderColor = ok ? .green : .red
        } else {
            feedbackMessage = "Next image captured, but no reference region drawn yet."
            borderColor = .clear
        }
        savedRightImages.append(img)
    }

    private func checkRegionOverlap() {
        guard let ref = leftImage,
              let nxt = rightImage,
              let region = selectedRegion else {
            feedbackMessage = "Missing images or region."
            return
        }
        let ok = imageOverlapChecker.checkRegionOverlap(
            image1: ref,
            image2: nxt,
            region: region
        )
        feedbackMessage = ok
            ? "The selected region overlaps!"
            : "No sufficient overlap in the selected region."
        borderColor = ok ? .green : .red
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
