//
//  RegionEditView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/4/25.
//

import SwiftUI

struct RegionEditView: View {
    let image: UIImage
    @Binding var selectedRect: CGRect?
    @Binding var isCompleted: Bool
    @Environment(\.presentationMode) private var presentationMode

    @State private var startPoint: CGPoint? = nil
    @State private var currentRect: CGRect = .zero

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }

            GeometryReader { geo in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    if startPoint == nil {
                                        startPoint = val.startLocation
                                    }
                                    let sp = startPoint!
                                    let cur = val.location
                                    currentRect = CGRect(
                                        x: min(sp.x, cur.x),
                                        y: min(sp.y, cur.y),
                                        width: abs(cur.x - sp.x),
                                        height: abs(cur.y - sp.y)
                                    )
                                }
                                .onEnded { _ in
                                
                                    selectedRect = convertViewRectToImageRect(
                                        currentRect,
                                        in: geo.size
                                    )
                                    isCompleted = true
                                    startPoint = nil
                                }
                        )

                        .highPriorityGesture(
                            TapGesture(count: 2)
                                .onEnded {
                  
                                    startPoint = nil
                                    currentRect = .zero
                                    selectedRect = nil
                                    isCompleted = false
                                }
                        )

      
                    if let rect = selectedRect {
                        let viewRect = convertImageRectToViewRect(
                            rect,
                            containerSize: geo.size
                        )
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: viewRect.width, height: viewRect.height)
                            .position(x: viewRect.midX, y: viewRect.midY)
                    }
    
                    else if currentRect != .zero {
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: currentRect.width, height: currentRect.height)
                            .position(x: currentRect.midX, y: currentRect.midY)
                    }
                }
            }
            .padding()


            Text("Double‑tap the image to clear selection")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }

   

    private func convertViewRectToImageRect(_ rect: CGRect, in containerSize: CGSize) -> CGRect {
        let iw = image.size.width
        let ih = image.size.height
        let scale = min(containerSize.width / iw, containerSize.height / ih)

        let displayedWidth = iw * scale
        let displayedHeight = ih * scale
        let offsetX = (containerSize.width - displayedWidth) / 2
        let offsetY = (containerSize.height - displayedHeight) / 2

        let adjustedX = rect.origin.x - offsetX
        let adjustedY = rect.origin.y - offsetY
        let pixelScale = 1 / scale

        return CGRect(
            x: adjustedX * pixelScale,
            y: adjustedY * pixelScale,
            width: rect.size.width * pixelScale,
            height: rect.size.height * pixelScale
        )
    }

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
