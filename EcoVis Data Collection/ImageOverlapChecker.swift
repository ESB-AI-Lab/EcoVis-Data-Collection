//
//  ImageOverlapChecker.swift
//  EcoVis Data Collection
//
//  Created by Vats Narsaria on 12/28/24.
//

import Accelerate
import UIKit

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
        
        // Extract right half of the first image
        let rightHalf1 = extractRegion(from: data1, width: width, height: height, startX: halfWidth, regionWidth: halfWidth)
        
        // Extract left half of the second image
        let leftHalf2 = extractRegion(from: data2, width: width, height: height, startX: 0, regionWidth: halfWidth)
        
        // Compare the extracted regions
        if let similarity = compareImageRegions(rightHalf1, leftHalf2, width: halfWidth, height: height) {
            print("Final Similarity Score: \(similarity)")
            return similarity > 0.8  // Overlap if similarity is above 80%
        }
        
        print("Region comparison failed.")
        return false
    }
    
    // Extract a region from the image data
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
    
    // Compare two image regions
    func compareImageRegions(_ region1: [UInt8], _ region2: [UInt8], width: Int, height: Int) -> Double? {
        guard region1.count == region2.count else {
            print("Region sizes do not match: \(region1.count) vs \(region2.count)")
            return nil
        }
        
        // Convert regions to float arrays
        var floatData1 = [Float](repeating: 0, count: width * height)
        var floatData2 = [Float](repeating: 0, count: width * height)
        vDSP.convertElements(of: region1, to: &floatData1)
        vDSP.convertElements(of: region2, to: &floatData2)
        
        // Normalize pixel values to [0, 1]
        vDSP.divide(floatData1, 255.0, result: &floatData1)
        vDSP.divide(floatData2, 255.0, result: &floatData2)
        
        // Calculate absolute differences
        var resultData = [Float](repeating: 0, count: width * height)
        vDSP.subtract(floatData2, floatData1, result: &resultData)
        vDSP.absolute(resultData, result: &resultData)
        
        // Calculate similarity
        let sum: Float = vDSP.sum(resultData)
        let totalPixels = width * height
        let averageDifference = Double(sum) / Double(totalPixels)
        let similarity = 1 - averageDifference  // Similarity decreases as difference increases

        // Debugging
        print("Sum of Differences: \(sum)")
        print("Average Difference Ratio: \(averageDifference)")
        print("Similarity Score: \(similarity)")
        
        return similarity
    }

    
    // Convert UIImage to grayscale data
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

