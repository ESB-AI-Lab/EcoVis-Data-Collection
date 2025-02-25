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
            // Apply the border as a background.
            Rectangle()
                .stroke(borderColor, lineWidth: 20)
            
            VStack(spacing: 20) {
                // Display the captured images or placeholders.
                HStack {
                    VStack {
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

                // Button to capture images.
                if firstImage == nil || secondImage == nil {
                    Button(isCapturingFirstImage ? "Capture First Image" : "Capture Second Image") {
                        showCamera()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Retake buttons (displayed only after both images are taken).
                if firstImage != nil && secondImage != nil {
                    HStack {
                        Button("Retake First") {
                            isCapturingFirstImage = true
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

                // Check object overlap if both images are captured.
                if firstImage != nil && secondImage != nil {
                    Button("Check Overlap") {
                        checkObjectOverlap()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Show feedback message.
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
                    // Update state: if first image was just captured, switch to capturing second.
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
    
    func checkObjectOverlap() {
        guard let firstImage = firstImage, let secondImage = secondImage else { return }
        
        imageOverlapChecker.checkObjectOverlap(image1: firstImage, image2: secondImage) { overlapDetected in
            DispatchQueue.main.async {
                if overlapDetected {
                    feedbackMessage = "The selected object overlaps!"
                    borderColor = .green
                } else {
                    feedbackMessage = "No overlap detected for the selected object."
                    borderColor = .red
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



