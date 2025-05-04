//
//  RegionEditorView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/4/25.
//

// RegionEditorView.swift
// EcoVis Data Collection
//
// Full-screen region editor that lets the user zoom & draw.

import SwiftUI
import UIKit

/// A UIViewRepresentable that embeds a zoomable UIScrollView with a UIImageView
/// and a transparent drawing overlay. The user can zoom/pan the image, then draw
/// a rectangle. The result is returned in image‐space via `drawnRect`.
struct ZoomableRegionSelectorView: UIViewRepresentable {
    var image: UIImage
    @Binding var drawnRect: CGRect?
    @Binding var isCompleted: Bool

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        scroll.delegate = context.coordinator
        scroll.bouncesZoom = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false

        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        iv.frame = scroll.bounds
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.addSubview(iv)
        context.coordinator.imageView = iv

        let overlay = DrawingOverlayView(frame: scroll.bounds)
        overlay.backgroundColor = .clear
        overlay.delegate = context.coordinator
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.addSubview(overlay)
        context.coordinator.overlay = overlay

        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIScrollViewDelegate, DrawingOverlayViewDelegate {
        var parent: ZoomableRegionSelectorView
        weak var imageView: UIImageView?
        weak var overlay: DrawingOverlayView?

        init(_ parent: ZoomableRegionSelectorView) { self.parent = parent }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        func drawingDidFinish(rect: CGRect) {
            guard let scroll = overlay?.superview as? UIScrollView else { return }
            let scale = scroll.zoomScale
            parent.drawnRect = CGRect(
                x: rect.origin.x / scale,
                y: rect.origin.y / scale,
                width: rect.size.width / scale,
                height: rect.size.height / scale
            )
            parent.isCompleted = true
        }
    }
}

/// A simple overlay that tracks touches to draw a rectangle.
class DrawingOverlayView: UIView {
    weak var delegate: DrawingOverlayViewDelegate?
    private var start: CGPoint?
    private var currentRect = CGRect.zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        start = touches.first?.location(in: self)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = start, let p = touches.first?.location(in: self) else { return }
        currentRect = CGRect(
            x: min(s.x, p.x), y: min(s.y, p.y),
            width: abs(p.x - s.x), height: abs(p.y - s.y)
        )
        setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.drawingDidFinish(rect: currentRect)
    }
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor.red.cgColor)
        ctx.setLineWidth(2)
        ctx.addRect(currentRect)
        ctx.strokePath()
    }
}

/// Protocol for the drawing overlay.
protocol DrawingOverlayViewDelegate: AnyObject {
    func drawingDidFinish(rect: CGRect)
}

/// Wraps the zoomable selector inside a navigation view with a Done button.
struct RegionEditorView: View {
    let image: UIImage
    @Binding var selectedRect: CGRect?
    @Binding var isCompleted: Bool
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationView {
            ZoomableRegionSelectorView(
                image: image,
                drawnRect: $selectedRect,
                isCompleted: $isCompleted
            )
            .navigationBarTitle("Edit Region", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentation.wrappedValue.dismiss()
                }
            )
        }
    }
}
