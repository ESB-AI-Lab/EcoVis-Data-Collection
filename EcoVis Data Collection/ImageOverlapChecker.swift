//
//  ImageOverlapChecker.swift
//  EcoVis Data Collection
//
//  Created by Vats Narsaria on 12/28/24.
//

import Accelerate
import UIKit
import Vision  // Import Vision framework for object detection

class ImageOverlapChecker {
    
    internal func checkImageOverlap(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard image1.size == image2.size else {
            print("Image sizes do not match: \(image1.size) vs \(image2.size)")
            return false
        }
        
        let width = Int(image1.size.width)
        let height = Int(image1.size.height)
        let halfWidth = width / 2
        
        guard
            let data1 = getGrayscaleData(from: image1),
            let data2 = getGrayscaleData(from: image2)
        else {
            print("Failed to extract grayscale data from one or both images.")
            return false
        }
        
        // Extract right half of the first image and left half of the second image
        let rightHalf1 = extractRegion(from: data1, width: width, height: height, startX: halfWidth, regionWidth: halfWidth)
        let leftHalf2 = extractRegion(from: data2, width: width, height: height, startX: 0, regionWidth: halfWidth)
        
        if let similarity = compareImageRegions(rightHalf1, leftHalf2, width: halfWidth, height: height) {
            print("Final Similarity Score: \(similarity)")
            return similarity > 0.8  // Overlap if similarity is above 80%
        }
        
        print("Region comparison failed.")
        return false
    }
    
    func checkObjectOverlap(image1: UIImage, image2: UIImage, completion: @escaping (Bool) -> Void) {
        // Detect the object region in the first image.
        detectObjectRegion(in: image1) { rect1 in
            guard let rect1 = rect1 else {
                print("No object detected in the first image.")
                completion(false)
                return
            }
            // Detect the object region in the second image.
            self.detectObjectRegion(in: image2) { rect2 in
                guard let rect2 = rect2 else {
                    print("No object detected in the second image.")
                    completion(false)
                    return
                }
                // Crop both images to the detected regions.
                guard let cropped1 = self.cropImage(image1, to: rect1),
                      let cropped2Original = self.cropImage(image2, to: rect2) else {
                    print("Failed to crop one or both images.")
                    completion(false)
                    return
                }
                // Resize second cropped image to match the first cropped image’s size if needed.
                let targetSize = cropped1.size
                guard let cropped2 = self.resizeImage(cropped2Original, targetSize: targetSize) else {
                    print("Failed to resize second image crop.")
                    completion(false)
                    return
                }
                // Extract grayscale data from both cropped regions.
                guard let data1 = self.getGrayscaleData(from: cropped1),
                      let data2 = self.getGrayscaleData(from: cropped2) else {
                    print("Failed to extract grayscale data from cropped regions.")
                    completion(false)
                    return
                }
                let width = Int(targetSize.width)
                let height = Int(targetSize.height)
                if let similarity = self.compareImageRegions(data1, data2, width: width, height: height) {
                    print("Similarity Score for object overlap: \(similarity)")
                    completion(similarity > 0.8)  // Overlap detected if similarity > 80%
                } else {
                    print("Region comparison failed.")
                    completion(false)
                }
            }
        }
    }
    
    func detectObjectRegion(in image: UIImage, completion: @escaping (CGRect?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        let request = VNDetectRectanglesRequest { request, error in
            if let results = request.results as? [VNRectangleObservation],
               let rectObservation = results.first {
                // Convert normalized coordinates to image coordinates.
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                let boundingBox = rectObservation.boundingBox
                // Vision's coordinate system is normalized with the origin in the bottom-left.
                let objectRect = CGRect(
                    x: boundingBox.origin.x * imageWidth,
                    y: (1 - boundingBox.origin.y - boundingBox.height) * imageHeight,
                    width: boundingBox.width * imageWidth,
                    height: boundingBox.height * imageHeight
                )
                completion(objectRect)
            } else {
                completion(nil)
            }
        }
        request.minimumConfidence = 0.8
        request.maximumObservations = 1
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error)")
            completion(nil)
        }
    }
    
    func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    

    func extractRegion(from data: [UInt8], width: Int, height: Int, startX: Int, regionWidth: Int) -> [UInt8] {
        var region = [UInt8]()
        for y in 0..<height {
            let startIndex = y * width + startX
            let endIndex = startIndex + regionWidth
            region.append(contentsOf: data[startIndex..<endIndex])
        }
        print("Region extracted successfully. Size: \(region.count)")
        return region
    }
    
    func compareImageRegions(_ region1: [UInt8], _ region2: [UInt8], width: Int, height: Int) -> Double? {
        guard region1.count == region2.count else {
            print("Region sizes do not match: \(region1.count) vs \(region2.count)")
            return nil
        }
        
        // Convert regions to float arrays.
        var floatData1 = [Float](repeating: 0, count: width * height)
        var floatData2 = [Float](repeating: 0, count: width * height)
        vDSP.convertElements(of: region1, to: &floatData1)
        vDSP.convertElements(of: region2, to: &floatData2)
        
        // Normalize pixel values to [0, 1].
        vDSP.divide(floatData1, 255.0, result: &floatData1)
        vDSP.divide(floatData2, 255.0, result: &floatData2)
        
        // Calculate absolute differences.
        var resultData = [Float](repeating: 0, count: width * height)
        vDSP.subtract(floatData2, floatData1, result: &resultData)
        vDSP.absolute(resultData, result: &resultData)
        
        // Calculate similarity.
        let sum: Float = vDSP.sum(resultData)
        let totalPixels = width * height
        let averageDifference = Double(sum) / Double(totalPixels)
        let similarity = 1 - averageDifference
        
        print("Sum of Differences: \(sum)")
        print("Average Difference Ratio: \(averageDifference)")
        print("Similarity Score: \(similarity)")
        return similarity
    }
    

    func getGrayscaleData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage.")
            return nil
        }
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let bitsPerComponent = 8
        let bytesPerRow = width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.none.rawValue
        var imageData = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &imageData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Failed to create CGContext.")
            return nil
        }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        print("Grayscale data extracted successfully. Size: \(imageData.count)")
        return imageData
    }
}
