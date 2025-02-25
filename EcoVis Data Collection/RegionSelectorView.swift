//
//  RegionSelectorView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 2/25/25.
//

import SwiftUI

/// A view that allows the user to draw a rectangular region over an image.
/// Once drawn, it converts the rectangle from view-space to the image's pixel-space
/// so that the same coordinates can be used in the second image for comparison.
struct RegionSelectorView: View {
    var image: UIImage
    @Binding var selectedRect: CGRect?
    @Binding var isCompleted: Bool
    var isEditable: Bool

    // Drag states for the user-drawn rectangle
    @State private var startPoint: CGPoint? = nil
    @State private var currentRect: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Only allow drawing if editing is enabled
                if isEditable {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if startPoint == nil {
                                        startPoint = value.startLocation
                                    }
                                    let sp = startPoint ?? value.startLocation
                                    let current = value.location
                                    currentRect = CGRect(
                                        x: min(sp.x, current.x),
                                        y: min(sp.y, current.y),
                                        width: abs(current.x - sp.x),
                                        height: abs(current.y - sp.y)
                                    )
                                }
                                .onEnded { _ in
                                    // Convert the drawn rect from view coords to the image's pixel coords
                                    selectedRect = convertViewRectToImageRect(currentRect, in: geometry.size)
                                    isCompleted = true
                                }
                        )
                }
                
                // Always display the final rectangle if selectedRect exists
                if let rect = selectedRect {
                    let viewRect = convertImageRectToViewRect(rect, containerSize: geometry.size)
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: viewRect.width, height: viewRect.height)
                        .position(x: viewRect.midX, y: viewRect.midY)
                    
                // If the user is still dragging (rectangle not yet finalized), show the temporary rectangle
                } else if currentRect != .zero {
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: currentRect.width, height: currentRect.height)
                        .position(x: currentRect.midX, y: currentRect.midY)
                }
                
                // Draw a prompt if we haven't completed the region yet
                if !isCompleted && isEditable {
                    Text("Draw area to select object")
                        .foregroundColor(.red)
                        .bold()
                        .padding(6)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
    
    /// Convert from the user-drawn rectangle in the overlay's view coords into image pixel coords.
    private func convertViewRectToImageRect(_ rect: CGRect, in containerSize: CGSize) -> CGRect {
        // The image is displayed with scaledToFit in a container of size containerSize.
        // So we compute the letterboxed frame for the displayed image, then offset + scale.
        
        let iw = image.size.width
        let ih = image.size.height
        let scale = min(containerSize.width / iw, containerSize.height / ih)
        
        let displayedWidth = iw * scale
        let displayedHeight = ih * scale
        
        let offsetX = (containerSize.width - displayedWidth) / 2
        let offsetY = (containerSize.height - displayedHeight) / 2
        
        // Adjust the user-drawn rect so it's relative to (0,0) of the displayed image
        let adjustedX = rect.origin.x - offsetX
        let adjustedY = rect.origin.y - offsetY
        
        // Multiply by (1/scale) to get actual image pixel coords
        let pixelScale = 1 / scale
        return CGRect(
            x: adjustedX * pixelScale,
            y: adjustedY * pixelScale,
            width: rect.size.width * pixelScale,
            height: rect.size.height * pixelScale
        )
    }
    
    /// Convert from an image-space rectangle to the overlay's view coords, for displaying the red rectangle.
    private func convertImageRectToViewRect(_ rect: CGRect, containerSize: CGSize) -> CGRect {
        let iw = image.size.width
        let ih = image.size.height
        let scale = min(containerSize.width / iw, containerSize.height / ih)
        
        let displayedWidth = iw * scale
        let displayedHeight = ih * scale
        
        let offsetX = (containerSize.width - displayedWidth) / 2
        let offsetY = (containerSize.height - displayedHeight) / 2
        
        return CGRect(
            x: rect.origin.x * scale + offsetX,
            y: rect.origin.y * scale + offsetY,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
    }
}
