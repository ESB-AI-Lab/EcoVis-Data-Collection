//
//  CameraView.swift
//  EcoVis Data Collection
//
//  Created by Kanishka on 10/04/24.
//
import SwiftUI
import UIKit

//Camera View structure(class) with implemented UIViewControllerRepresentable protocol(interface)
struct CameraView: UIViewControllerRepresentable {
    //Coordinator nested class to communicate between SwiftUI and UIImagePickerController
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        //CameraView reference
        var parent: CameraView
        
        //Constructor
        init(parent: CameraView) {
            self.parent = parent
        }
        
        //Method call when a picture is taken
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            //Null check and assign image data info
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageCaptured?(image)
            }
            //Close camera
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    //Dismissal Control
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    var onImageCaptured: ((UIImage) -> Void)?
    
    //Create and return an instance of Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    //Create UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        //Create a new instance
        let picker = UIImagePickerController()
        //Set Coordinator to handle when a picture is taken
        picker.delegate = /Users/kan/Documents/EcoVis-Data-Collection/EcoVis Data Collection/CameraView.swiftcontext.coordinator
        //Set source to camera
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        //Not implemented
    }
}
