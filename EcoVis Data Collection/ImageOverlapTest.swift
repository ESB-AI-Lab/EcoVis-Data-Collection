//
//  ImageOverlapTest.swift
//  EcoVis Data Collection
//
//  Created by Vats Narsaria on 12/28/24.
//



import UIKit
let imageOverlapChecker = ImageOverlapChecker()

func testImageOverlap() {
    guard
        let image1 = UIImage(named: "image1"),  // First image (black left, white right)
        let image2 = UIImage(named: "image2")   // Second image (white left, black right)
    else {
        print("Failed to load images.")
        return
    }
    
    let overlap = imageOverlapChecker.checkImageOverlap(image1, image2)
    
    if overlap {
        print("The images overlap!")
    } else {
        print("No overlap detected.")
    }
}
