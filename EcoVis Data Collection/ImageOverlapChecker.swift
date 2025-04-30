//
//  ImageOverlapChecker.swift
//  EcoVis Data Collection
//
//  Created by Vats Narsaria on 12/28/24.
//

import Accelerate
import UIKit

class ImageOverlapChecker {
    
    /// Existing method comparing fixed halves (kept for legacy use)
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
        
        let rightHalf1 = extractRegion(from: data1, width: width, height: height, startX: halfWidth, regionWidth: halfWidth)
        let leftHalf2 = extractRegion(from: data2, width: width, height: height, startX: 0, regionWidth: halfWidth)
        
        if let similarity = compareImageRegions(rightHalf1, leftHalf2, width: halfWidth, height: height) {
            print("Final Similarity Score: \(similarity)")
            return similarity > 0.8  // Overlap if similarity is above 80%
        }
        print("Region comparison failed.")
        return false
    }
    
    /// New method that uses the user-drawn region (assumed to be in image1’s coordinate space) for comparison.
    func checkRegionOverlap(image1: UIImage, image2: UIImage, region: CGRect) -> Bool {
        // Crop image1 to the drawn region.
        guard let cropped1 = cropImage(image1, to: region) else {
            print("Failed to crop first image to selected region.")
            return false
        }
        // Crop image2 to the same region.
        guard let cropped2 = cropImage(image2, to: region) else {
            print("Failed to crop second image to selected region.")
            return false
        }
        // Extract grayscale data from both cropped regions.
        guard let data1 = getGrayscaleData(from: cropped1),
              let data2 = getGrayscaleData(from: cropped2) else {
            print("Failed to extract grayscale data from cropped regions.")
            return false
        }
        
        let width = Int(cropped1.size.width)
        let height = Int(cropped1.size.height)
        if let similarity = compareImageRegions(data1, data2, width: width, height: height) {
            print("Region similarity score: \(similarity)")
            return similarity > 0.8  // Overlap detected if similarity > 80%
        }
        return false
    }
    
    // MARK: - Existing Helper Methods
    
    /// Extract a region from the image data.
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
    
    /// Compare two image regions and return a similarity score.
    func compareImageRegions(_ region1: [UInt8], _ region2: [UInt8], width: Int, height: Int) -> Double? {
        guard region1.count == region2.count else {
            print("Region sizes do not match: \(region1.count) vs \(region2.count)")
            return nil
        }
        var floatData1 = [Float](repeating: 0, count: width * height)
        var floatData2 = [Float](repeating: 0, count: width * height)
        vDSP.convertElements(of: region1, to: &floatData1)
        vDSP.convertElements(of: region2, to: &floatData2)
        vDSP.divide(floatData1, 255.0, result: &floatData1)
        vDSP.divide(floatData2, 255.0, result: &floatData2)
        var resultData = [Float](repeating: 0, count: width * height)
        vDSP.subtract(floatData2, floatData1, result: &resultData)
        vDSP.absolute(resultData, result: &resultData)
        let sum: Float = vDSP.sum(resultData)
        let totalPixels = width * height
        let averageDifference = Double(sum) / Double(totalPixels)
        let similarity = 1 - averageDifference
        print("Sum of Differences: \(sum)")
        print("Average Difference Ratio: \(averageDifference)")
        print("Similarity Score: \(similarity)")
        return similarity
    }
    
    /// Crops a UIImage to the specified CGRect.
    func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        // Ensure the crop rect is within the image bounds.
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let cropRect = rect.intersection(imageRect)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage)
    }
    
    /// Converts a UIImage to grayscale data.
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
    
    // (resizeImage remains available if needed)
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}




