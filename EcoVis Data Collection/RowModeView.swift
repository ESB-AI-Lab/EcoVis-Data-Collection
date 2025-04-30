//  RowModeView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//

import SwiftUI

struct RowModeView: View {
    // MARK: State
    @State private var rowStarted = false
    @State private var currentRow = 1
    @State private var frontCount = 0
    @State private var currentObject = 1
    @State private var backside = false

    @State private var referenceImage: UIImage? = nil
    @State private var nextImage: UIImage? = nil

    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted = false
    @State private var regionEditing = true

    @State private var isShowingCamera = false
    @State private var isCapturingReference = true

    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var savedData: [String: [UIImage]] = [:]

    @State private var showSaved = false

    let checker = ImageOverlapChecker()

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(borderColor, lineWidth: 20)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                Text("Take a reference image from the left/right side of each object, and take photos rotating 180° toward the opposite side of the reference. Then, continue for the reverse side of each object in the same row, and repeat for each new row while pathing in a zig zag pattern.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.blue)
                    .padding()

                if !rowStarted {
                    Button("New Row") {
                        startNewRow()
                    }
                    .rowButtonStyle(color: .blue)

                } else {
                    Text("Row \(currentRow) — \(backside ? "Backside" : "Frontside") Object \(currentObject)")
                        .font(.headline)

                    HStack {
                        previewColumn(title: "Reference", image: referenceImage)
                            .overlay(regionOverlay)
                        previewColumn(title: "Next", image: nextImage)
                    }

                    HStack {
                        Button("Capture Reference Image") {
                            isCapturingReference = true
                            showCamera()
                        }
                        .rowButtonStyle(color: .orange)

                        Button("Capture Next Image") {
                            isCapturingReference = false
                            showCamera()
                        }
                        .rowButtonStyle(color: .purple)
                    }

                    HStack(spacing: 12) {
                        Button("New Row") { newRowPressed() }
                            .rowButtonStyle(color: .blue)

                        Button("Reverse Side of Row") { reverseSidePressed() }
                            .rowButtonStyle(color: .gray)

                        Button("Next Object") { newObjectPressed() }
                            .rowButtonStyle(color: .green)
                    }
                }

                if rowStarted {
                    Button("Upload") {
                        if backside,
                           referenceImage != nil,
                           nextImage != nil
                        {
                            saveCurrentBackside()
                        }
                        showSaved = true
                    }
                    .rowButtonStyle(color: .pink)
                }

                if !feedbackMessage.isEmpty {
                    Text(feedbackMessage)
                        .foregroundColor(borderColor)
                }
            }
            .padding()
        }
        .navigationTitle("Row Mode")
        .sheet(isPresented: $isShowingCamera) {
            CameraView(image: isCapturingReference ? $referenceImage : $nextImage)
                .onDisappear {
                    if isCapturingReference { handleReferenceCaptured() }
                    else { handleNextCaptured() }
                }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showSaved) {
            SavedRowObjectsView(savedData: savedData,
                                onReset: globalReset)
        }
    }


    private func previewColumn(title: String, image: UIImage?) -> some View {
        VStack {
            Text(title)
            ZStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .stroke(Color.gray)
                        .overlay(Text("None"))
                }
            }
            .frame(height: 120)
        }
    }

    private var regionOverlay: some View {
        RegionSelectorView(
            image: referenceImage ?? UIImage(),
            selectedRect: $selectedRegion,
            isCompleted: $regionSelectionCompleted,
            isEditable: regionEditing
        )
    }


    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }


    private func startNewRow() {
        if backside,
           referenceImage != nil,
           nextImage != nil
        {
            saveCurrentBackside()
        }
        rowStarted = true
        frontCount = 0
        currentObject = 1
        backside = false
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        regionEditing = true
        borderColor = .clear
        feedbackMessage = "Row \(currentRow) started.\nDraw region & capture images."
    }

    private func handleReferenceCaptured() {
        feedbackMessage = "Reference captured for object \(currentObject)."
    }

    private func handleNextCaptured() {
        feedbackMessage = "Next image captured."
        if let ref = referenceImage,
           let nxt = nextImage,
           let region = selectedRegion,
           regionSelectionCompleted
        {
            let ok = checker.checkRegionOverlap(
                image1: ref,
                image2: nxt,
                region: region
            )
            feedbackMessage = ok ? "Overlap Detected" : "No overlap"
            borderColor = ok ? .green : .red
        }
    }

    private func newObjectPressed() {
        guard let ref = referenceImage,
              let nxt = nextImage else {
            errorMessage = "Capture both images before Next Object."
            showErrorAlert = true
            return
        }
        let key = "Row \(currentRow) Object \(currentObject)"

        if !backside {
            savedData[key] = [ref, nxt]
            frontCount += 1
            currentObject += 1
        } else {
            if var arr = savedData[key] {
                arr.append(contentsOf: [ref, nxt])
                savedData[key] = arr
            } else {
                savedData[key] = [ref, nxt]
            }
            if currentObject > 1 {
                currentObject -= 1
            }
        }

        feedbackMessage = "\(key) saved."
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        regionEditing = true
    }

    private func reverseSidePressed() {
        if !backside,
           referenceImage != nil,
           nextImage != nil
        {
            let key = "Row \(currentRow) Object \(currentObject)"
            savedData[key] = [referenceImage!, nextImage!]
            frontCount += 1
        }
        guard frontCount > 0 else {
            errorMessage = "No front-side objects captured yet."
            showErrorAlert = true
            return
        }
        backside = true
        currentObject = frontCount
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        regionEditing = true
        feedbackMessage = "Backside start at object \(currentObject)."
    }

    private func newRowPressed() {
        if backside,
           referenceImage != nil,
           nextImage != nil
        {
            saveCurrentBackside()
        }
        currentRow += 1
        startNewRow()
    }

    private func saveCurrentBackside() {
        let key = "Row \(currentRow) Object \(currentObject)"
        if let ref = referenceImage,
           let nxt = nextImage,
           var arr = savedData[key]
        {
            arr.append(contentsOf: [ref, nxt])
            savedData[key] = arr
            feedbackMessage = "Backside for \(key) saved."
        }
    }

    private func globalReset() {
        rowStarted = false
        currentRow = 1
        frontCount = 0
        currentObject = 1
        backside = false
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        regionEditing = true
        feedbackMessage = ""
        borderColor = .clear
        savedData.removeAll()
    }
}

private extension View {
    func rowButtonStyle(color: Color) -> some View {
        self
            .font(.subheadline)
            .padding(8)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}
