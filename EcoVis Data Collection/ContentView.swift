//
//  ContentView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/6/25
//
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct ContentView: View {
    @Binding var selectedMode: EcoVis_Data_CollectionApp.Mode?

    @State private var leftImage: UIImage? = nil
    @State private var rightImage: UIImage? = nil

    @State private var savedLeftImages: [UIImage] = []
    @State private var savedRightImages: [UIImage] = []

    @State private var isShowingCamera = false
    @State private var isCapturingLeft = true

    @State private var selectedRegion: CGRect? = nil
    @State private var regionSelectionCompleted = false

    @State private var showRegionEditor = false
    @State private var feedbackMessage = ""
    @State private var borderColor: Color = .clear

    // — naming/upload —
    @State private var isNamingProject = false
    @State private var projectName = ""
    @State private var isUploading = false

    // saved-images sheet
    @State private var showSavedImages = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let imageOverlapChecker = ImageOverlapChecker()

    var body: some View {
        NavigationView {
            ZStack {
                // Colored border to indicate overlap status (green/red)
                Rectangle()
                    .stroke(borderColor, lineWidth: 20)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Instructions
                    Text("Retake reference image each time you have rotated 90° around the object. Keep object centered within the region you selected.")
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding()

                    // Preview Row: Reference on the left, "Next" on the right
                    HStack(spacing: 16) {
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
                            .overlay(regionOverlay) // Show the drawn region, if any
                        }
                        .onTapGesture {
                            // Only allow editing if we have a reference image
                            guard leftImage != nil else { return }
                            showRegionEditor = true
                        }

                        // “Next” preview column
                        previewColumn(title: "Next", image: rightImage)
                    }

                    // Button: Capture Reference
                    Button("Capture Reference Image") {
                        isCapturingLeft = true
                        showCamera()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    // Button: Capture Next
                    Button("Capture Next Image") {
                        isCapturingLeft = false
                        showCamera()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    // “Check Overlap” only if both images and a drawn region exist
                    if leftImage != nil,
                       rightImage != nil,
                       regionSelectionCompleted,
                       selectedRegion != nil {
                        Button("Check Overlap") {
                            checkRegionOverlap()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Upload Button
                    Button("Upload") {
                        projectName = ""
                        isNamingProject = true
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    // Feedback label (e.g. “Overlap detected” / “No overlap”)
                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .foregroundColor(borderColor == .green ? .green : .red)
                            .padding()
                    }

                    // Show all saved images (reference + successful overlap “next”)
                    Button("View Saved Images") {
                        showSavedImages = true
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Object Mode")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // ← Back arrow to return to ModeSelectionView
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selectedMode = nil
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
            // Full‐screen region editor (draw bounding box on reference)
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
                CameraView(image: isCapturingLeft ? $leftImage : $rightImage) { _ in
                    if isCapturingLeft {
                        handleNewLeftImage()
                    } else {
                        handleNewRightImage()
                    }
                }
            }
            // Saved images sheet (now uses a merged array)
            .sheet(isPresented: $showSavedImages) {
                // Merge reference + successful Next images into one array
                let allImages = savedLeftImages + savedRightImages
                SavedImagesView(
                    images: allImages,
                    onReset: resetAll
                )
            }
            // Project naming & upload sheet
            .sheet(isPresented: $isNamingProject) {
                ProjectNamingView(
                    projectName: $projectName,
                    isUploading: $isUploading
                ) {
                    Task {
                        isNamingProject = false
                        await uploadObjectProject(named: projectName)
                    }
                }
            }
        }
    }

    // MARK: – Helper Views & Methods

    /// “Next” preview column
    private func previewColumn(title: String, image: UIImage?) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
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
            .frame(height: 150)
        }
    }

    /// Overlay the user‐drawn region rectangle on the reference image
    private var regionOverlay: some View {
        RegionSelectorView(
            image: leftImage ?? UIImage(),
            selectedRect: $selectedRegion,
            isCompleted: $regionSelectionCompleted,
            isEditable: false
        )
    }

    /// Show the camera; workaround to force SwiftUI to re‐present
    private func showCamera() {
        isShowingCamera = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }

    /// Always save the reference (left) image
    private func handleNewLeftImage() {
        guard let img = leftImage else { return }
        savedLeftImages.append(img)
        regionSelectionCompleted = false
        selectedRegion = nil
        feedbackMessage = "Captured new reference image. Draw region & capture next image."
        borderColor = .clear
    }

    /// For “Next” capture: only append if overlap passes
    private func handleNewRightImage() {
        guard let img = rightImage else { return }

        // If we have a reference + drawn region, check overlap
        if let ref = leftImage,
           let region = selectedRegion,
           regionSelectionCompleted
        {
            let ok = imageOverlapChecker.checkRegionOverlap(
                image1: ref,
                image2: img,
                region: region
            )

            if ok {
                // Overlap passed → save it
                feedbackMessage = "Overlap detected. Image saved."
                borderColor = .green
                savedRightImages.append(img)
            } else {
                // Overlap failed → do NOT save
                feedbackMessage = "No overlap—image not saved."
                borderColor = .red
            }
        } else {
            // No region drawn yet
            feedbackMessage = "Next image captured, but no region drawn."
            borderColor = .clear
        }
    }

    /// Manually invoked “Check Overlap” button (for explicit feedback)
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
            : "No sufficient overlap."
        borderColor = ok ? .green : .red
    }

    /// Reset everything (clears both saved arrays)
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

    // MARK: – Upload Logic

    /// Uploads both reference + successful Next images under one “objects” folder
    private func uploadObjectProject(named name: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            feedbackMessage = "Missing user ID"
            borderColor = .red
            return
        }
        isUploading = true
        feedbackMessage = "Uploading…"

        // Merge both arrays
        let allImages = savedLeftImages + savedRightImages

        // Build a StorageReference path: users/{uid}/projects/{name}/objects/{i}.jpg
        let baseRef = storage.reference()
            .child("users")
            .child(uid)
            .child("projects")
            .child(name)
            .child("objects")

        // Firestore document for this project
        let projectDoc = db
            .collection("users")
            .document(uid)
            .collection("projects")
            .document(name)

        do {
            var urls: [String] = []

            // Upload each image as “{i}.jpg”
            for (i, img) in allImages.enumerated() {
                guard let data = img.jpegData(compressionQuality: 0.8) else { continue }
                let fileRef = baseRef.child("\(i).jpg")
                _ = try await fileRef.putDataAsync(data, metadata: nil)
                let downloadURL = try await fileRef.downloadURL()
                urls.append(downloadURL.absoluteString)
            }

            // Write the array of URLs into Firestore under a single “objects” field
            try await projectDoc.setData([
                "objects": urls
            ], merge: true)

            feedbackMessage = "Upload complete!"
            borderColor = .green
        } catch {
            feedbackMessage = "Upload failed: \(error.localizedDescription)"
            borderColor = .red
        }

        isUploading = false
    }
}
