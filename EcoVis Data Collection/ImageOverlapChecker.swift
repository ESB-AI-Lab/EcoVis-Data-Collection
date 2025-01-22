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
            return false
        }
        
        let width = Int(image1.size.width)
        let height = Int(image1.size.height)
        let halfWidth = width / 2
        
        guard
            let data1 = getGrayscaleData(from: image1),
            let data2 = getGrayscaleData(from: image2)
        else {
            return false
        }
        
        // Extract right half of the first image
        let rightHalf1 = extractRegion(from: data1, width: width, height: height, startX: halfWidth, regionWidth: halfWidth)
        
        // Extract left half of the second image
        let leftHalf2 = extractRegion(from: data2, width: width, height: height, startX: 0, regionWidth: halfWidth)
        
        // Compare the extracted regions
        if let similarity = compareImageRegions(rightHalf1, leftHalf2, width: halfWidth, height: height) {
            return similarity > 0.8  // Overlap if similarity is above 80%
        }
        
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
        
        return region
    }
    
    // Compare two image regions
    func compareImageRegions(_ region1: [UInt8], _ region2: [UInt8], width: Int, height: Int) -> Double? {
        guard region1.count == region2.count else {
            return nil
        }
        //Initizialize variables
        var floatData1 = [Float](repeating: 0, count: width * height)
        var floatData2 = [Float](repeating: 0, count: width * height)
        var resultData = [Float](repeating: 0, count: width * height)
        
        //Convert to float
        vDSP.convertElements(of: region1, to: &floatData1)
        vDSP.convertElements(of: region2, to: &floatData2)
        
        //Calculate absolute difference for each pixel
        vDSP.subtract(floatData2, floatData1, result: &resultData)
        vDSP.absolute(resultData, result: &resultData)
        
        let sum: Float = vDSP.sum(resultData)
        let ratio = Double(sum) / Double(width * height)
        let similarity = 1 - ratio
        
        return similarity
    }
    
    // Convert UIImage to grayscale data
    func getGrayscaleData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else {
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
            return nil
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        return imageData
    }
    
    
}
