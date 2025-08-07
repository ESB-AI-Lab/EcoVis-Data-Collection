//  RowModeView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct RowModeView: View {
    @Binding var selectedMode: EcoVis_Data_CollectionApp.Mode?

    // MARK: – State
    @State private var rowStarted = false
    @State private var currentRow = 1
    @State private var frontCount = 0
    @State private var currentObject = 1
    @State private var backside = false

    @State private var referenceImage: UIImage? = nil
    @State private var nextImage: UIImage? = nil

    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted = false

    @State private var isShowingCamera = false
    @State private var isCapturingReference = true
    @State private var showRegionEditor = false

    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear
    @State private var showErrorAlert = false
    @State private var errorMessage = ""


    @State private var savedData: [String: [UIImage]] = [:]

    @State private var isNamingProject = false
    @State private var projectName = ""
    @State private var isUploading = false

    @State private var showSavedImages = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let checker = ImageOverlapChecker()

    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .stroke(borderColor, lineWidth: 20)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    Text("""
                        Take a reference image from the left/right side of each object, and take photos rotating \
                        180° toward the opposite side of the reference. Then, continue for the reverse side of \
                        each object in the same row, and repeat for each new row while pathing in a zig zag \
                        pattern. Keep object centered within the region you selected in the reference image in \
                        each proceeding image to ensure best overlap detection results.
                        """)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.blue)
                        .padding()

                    if !rowStarted {
                        Button("New Row", action: startNewRow)
                            .rowButtonStyle(color: .blue)
                    } else {
                        Text("Row \(currentRow) — \(backside ? "Backside" : "Frontside") Object \(currentObject)")
                            .font(.headline)

                        HStack {
                            VStack {
                                Text("Reference")
                                ZStack {
                                    if let img = referenceImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 120)
                                            .overlay(
                                                RegionSelectorView(
                                                    image: img,
                                                    selectedRect: $selectedRegion,
                                                    isCompleted: $regionSelectionCompleted,
                                                    isEditable: false
                                                )
                                            )
                                            .onTapGesture { showRegionEditor = true }
                                    } else {
                                        Rectangle()
                                            .stroke(Color.gray)
                                            .overlay(Text("None").foregroundColor(.gray))
                                            .frame(height: 120)
                                    }
                                }
                                .frame(height: 120)
                            }

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
                            Button("New Row", action: newRowPressed)
                                .rowButtonStyle(color: .blue)
                            Button("Reverse Side of Row", action: reverseSidePressed)
                                .rowButtonStyle(color: .gray)
                            Button("Next Object", action: newObjectPressed)
                                .rowButtonStyle(color: .green)
                        }
                    }

                    if rowStarted {
                        Button("Upload") {
                            if backside,
                               referenceImage != nil,
                               nextImage != nil {
                                saveCurrentBackside()
                            }
                            projectName = ""
                            isNamingProject = true
                        }
                        .rowButtonStyle(color: .pink)

                        Text("Tap the reference image to edit the region")
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        // new “View Saved Images” button
                        Button("View Saved Images") {
                            showSavedImages = true
                        }
                        .rowButtonStyle(color: .secondary)
                        .padding(.top, 4)
                    }

                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .foregroundColor(borderColor)
                    }
                }
                .padding()
            }
            .navigationTitle("Row Mode")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selectedMode = nil
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
            .fullScreenCover(isPresented: $showRegionEditor) {
                if let img = referenceImage {
                    RegionEditView(
                        image: img,
                        selectedRect: $selectedRegion,
                        isCompleted: $regionSelectionCompleted
                    )
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraView(image: isCapturingReference ? $referenceImage : $nextImage)
                    .onDisappear {
                        if isCapturingReference {
                            handleReferenceCaptured()
                        } else {
                            handleNextCaptured()
                        }
                    }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $isNamingProject) {
                ProjectNamingView(
                    projectName: $projectName,
                    isUploading: $isUploading
                ) {
                    Task {
                        isNamingProject = false
                        await uploadRowProject(named: projectName)
                    }
                }
            }
            // → new sheet showing all savedData in list form
            .sheet(isPresented: $showSavedImages) {
                SavedRowObjectsView(
                    savedData: savedData,
                    onReset: resetAll
                )
            }
        }
    }

    // MARK: – Helper Views & Methods

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
                        .overlay(Text("None").foregroundColor(.gray))
                }
            }
            .frame(height: 120)
        }
    }

    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }

    private func startNewRow() {
        rowStarted = true
        frontCount = 0
        currentObject = 1
        backside = false
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        borderColor = .clear
        feedbackMessage = "Row \(currentRow) started. Draw region & capture images."
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
            let ok = checker.checkRegionOverlap(image1: ref, image2: nxt, region: region)
            feedbackMessage = ok
                ? "Overlap Detected. Tap Next Object to save."
                : "No overlap. Image will not be saved."
            borderColor = ok ? .green : .red
            // We do NOT append `nxt` here; appending happens in newObjectPressed()
        }
    }

    private func newObjectPressed() {
        guard let ref = referenceImage, let nxt = nextImage else {
            errorMessage = "Capture both images before Next Object."
            showErrorAlert = true
            return
        }
        guard let region = selectedRegion, regionSelectionCompleted else {
            errorMessage = "No region selected."
            showErrorAlert = true
            return
        }
        let ok = checker.checkRegionOverlap(image1: ref, image2: nxt, region: region)
        guard ok else {
            errorMessage = "Overlap failed—cannot save this object."
            showErrorAlert = true
            return
        }

        let key = "Row \(currentRow)_Object_\(currentObject)"
        var arr = savedData[key] ?? []
        arr.append(contentsOf: [ref, nxt])
        savedData[key] = arr

        if !backside {
            frontCount += 1
            currentObject += 1
        } else {
            if currentObject > 1 {
                currentObject -= 1
            }
        }
        feedbackMessage = "\(key) saved."
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
    }

    private func reverseSidePressed() {
        // Save front side only if overlap ok
        if !backside,
           let ref = referenceImage,
           let nxt = nextImage,
           let region = selectedRegion,
           regionSelectionCompleted
        {
            let ok = checker.checkRegionOverlap(image1: ref, image2: nxt, region: region)
            guard ok else {
                errorMessage = "Overlap failed—cannot switch to backside."
                showErrorAlert = true
                return
            }
            let key = "Row \(currentRow)_Object_\(currentObject)"
            savedData[key] = [ref, nxt]
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
        guard let ref = referenceImage,
              let nxt = nextImage,
              let region = selectedRegion,
              regionSelectionCompleted
        else {
            return
        }
        let ok = checker.checkRegionOverlap(image1: ref, image2: nxt, region: region)
        guard ok else {
            errorMessage = "Overlap failed—backside not saved."
            showErrorAlert = true
            return
        }
        let key = "Row \(currentRow)_Object_\(currentObject)"
        var arr = savedData[key] ?? []
        arr.append(contentsOf: [ref, nxt])
        savedData[key] = arr
        feedbackMessage = "Backside for \(key) saved."
    }

    // MARK: – Upload logic

    private func uploadRowProject(named name: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            feedbackMessage = "Missing user ID"
            borderColor = .red
            return
        }
        isUploading = true
        feedbackMessage = "Uploading…"
        borderColor = .clear

        let storageFolder = "users/\(uid)/projects/\(name)/rows"
        let projectDoc = db
            .collection("users").document(uid)
            .collection("projects").document(name)

        do {
            // 1) Touch the parent document so it appears in History
            try await projectDoc.setData([
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)

            // 2) Upload each row’s images into subcollection “rows”
            for (key, images) in savedData {
                let safeKey = key.replacingOccurrences(of: " ", with: "_")
                var urls: [String] = []

                for (i, img) in images.enumerated() {
                    if let data = img.jpegData(compressionQuality: 0.8) {
                        let imageRef = storage.reference()
                            .child("\(storageFolder)/\(safeKey)/\(i).jpg")
                        _ = try await imageRef.putDataAsync(data, metadata: nil)
                        let downloadURL = try await imageRef.downloadURL()
                        urls.append(downloadURL.absoluteString)
                    }
                }

                try await projectDoc
                    .collection("rows")
                    .document(safeKey)
                    .setData(["images": urls], merge: true)
            }

            feedbackMessage = "Upload complete!"
            borderColor = .green
        } catch {
            feedbackMessage = "Upload failed: \(error.localizedDescription)"
            borderColor = .red
        }
        isUploading = false
    }

    // Reset everything, including savedData
    private func resetAll() {
        rowStarted = false
        currentRow = 1
        frontCount = 0
        currentObject = 1
        backside = false
        referenceImage = nil
        nextImage = nil
        selectedRegion = nil
        regionSelectionCompleted = false
        feedbackMessage = ""
        borderColor = .clear
        savedData.removeAll()
    }
}

// MARK: – Styles

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


