//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    // MARK: State
    @State private var leftImage: UIImage? = nil    // Reference image
    @State private var rightImage: UIImage? = nil   // Next image

    @State private var savedLeftImages: [UIImage] = []
    @State private var savedRightImages: [UIImage] = []

    @State private var isShowingCamera = false
    @State private var isCapturingLeft = true

    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted = false

    @State private var showRegionEditor = false
    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear

    @State private var showSavedImages = false

    let imageOverlapChecker = ImageOverlapChecker()

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(borderColor, lineWidth: 20)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Instruction
                Text("Retake reference image each time you have rotated 90° around the object")
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()

                // Previews
                HStack(spacing: 16) {
                    // —— Reference Preview ——
                    VStack {
                        Text("Reference")
                            .font(.subheadline)
                        ZStack {
                            if let img = leftImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Rectangle()
                                    .stroke(Color.gray)
                                    .overlay(Text("None").foregroundColor(.gray))
                            }
                        }
                        .frame(height: 150)
                        .overlay(regionOverlay)       // draw the red box here
                    }
                    .onTapGesture {
                        guard leftImage != nil else { return }
                        showRegionEditor = true
                    }

                    // —— Next Preview ——
                    previewColumn(title: "Next", image: rightImage)
                }

                // Capture buttons
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

                // Check Overlap
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

                // Upload
                Button("Upload") {
                    showSavedImages = true
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Feedback
                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor == .green ? .green : .red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Object Mode")

        // Full-screen region editor
        .fullScreenCover(isPresented: $showRegionEditor) {
            if let img = leftImage {
                RegionEditView(
                    image: img,
                    selectedRect: $selectedRegion,
                    isCompleted: $regionSelectionCompleted
                )
            }
        }

        // Camera sheet
        .sheet(isPresented: $isShowingCamera) {
            CameraView(image: isCapturingLeft ? $leftImage : $rightImage)
                .onDisappear {
                    if isCapturingLeft { handleNewLeftImage() }
                    else             { handleNewRightImage() }
                }
        }

        // Saved‑images sheet
        .sheet(isPresented: $showSavedImages) {
            SavedImagesView(
                leftImages: savedLeftImages,
                rightImages: savedRightImages,
                onReset: resetAll
            )
        }
    }

    // MARK: – Helpers

    /// The generic “Next” preview column
    private func previewColumn(title: String, image: UIImage?) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
            ZStack {
                if let ui = image {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .stroke(Color.gray)
                        .overlay(Text("None").foregroundColor(.gray))
                }
            }
            .frame(height: 150)
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
        feedbackMessage = ""
        borderColor = .clear
    }

    /// Draws the saved region over the small preview
    private var regionOverlay: some View {
        RegionSelectorView(
            image: leftImage ?? UIImage(),
            selectedRect: $selectedRegion,
            isCompleted: $regionSelectionCompleted,
            isEditable: false
        )
    }
}
