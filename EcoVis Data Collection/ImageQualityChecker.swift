//
//  ImageQualityChecker.swift
//  EcoVis Data Collection
//
//  Created by Kanishka on 11/3/24.
//
import UIKit
import CoreImage

class ImageQualityChecker {
    private let blurThreshold: Float = 780.0 //Needs testing
    
    func performBlurrinessCheck(for image: UIImage) -> Bool{
        guard let cgImage = image.cgImage else { return false }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        let laplacianKernelString = """
        kernel vec4 laplacian(sampler image) {
            // Get the current pixel coordinates (x, y) being processed
            vec2 d = destCoord();
            
            // Compute the Laplacian value using the neighboring pixels and the current pixel
            float value = -1.0 * sample(image, samplerTransform(image, d + vec2(-1.0, 0.0))).r  // Left neighbor
                          -1.0 * sample(image, samplerTransform(image, d + vec2(1.0, 0.0))).r   // Right neighbor
                          -1.0 * sample(image, samplerTransform(image, d + vec2(0.0, -1.0))).r  // Top neighbor
                          -1.0 * sample(image, samplerTransform(image, d + vec2(0.0, 1.0))).r   // Bottom neighbor
                          +4.0 * sample(image, samplerTransform(image, d)).r;                   // Current pixel
            
            // Construct and return a grayscale color with the computed Laplacian value
            // vec3(value) sets the same intensity value for red, green, and blue channels
            return vec4(vec3(value), 1.0);
        }
        """

               
               // Create the Laplacian kernel
               guard let laplacianKernel = CIKernel(source: laplacianKernelString) else { return false }
               
               // Apply the kernel to the image
        guard let outputImage = laplacianKernel.apply(extent: ciImage.extent, roiCallback: {_, rect in rect }, arguments: [ciImage]) else {
                   return false
               }
               
        
        // Check if filter succeeded and calculate the variance
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent),
              let pixelData = outputCGImage.dataProvider?.data else {
            return false
        }
        
        let variance = calculateVariance(from: pixelData)
        return variance > blurThreshold
    }
    
    private func calculateVariance(from pixelData: CFData) -> Float {
        let length = CFDataGetLength(pixelData)
        let buffer = CFDataGetBytePtr(pixelData)! 

        var sum: Float = 0.0
        var sumOfSquares: Float = 0.0
        let pixelCount = length / 4

        for i in 0..<pixelCount {
            let intensity = Float(buffer[i * 4])
            sum += intensity
            sumOfSquares += intensity * intensity
        }

        let mean = sum / Float(pixelCount)
        let variance = (sumOfSquares / Float(pixelCount)) - (mean * mean)
        return variance
    }
    
    func calculateBrightness(for image: UIImage) -> CGFloat {
        //We need to convert the image into raw pixel data to be iterated over.
        guard let rawData = extractPixelData(from: image) else { return 0 }
        
        let width = image.cgImage!.width
        let height = image.cgImage!.height
        let bytesPerPixel = 4
        var totalBrightness: CGFloat = 0
        //Iterate over each pixel using nested loop with x and y coordinates
        for y in 0..<height {
            for x in 0..<width {
                //Calculate the starting index of the pixel within the image data array
                let pixelIndex = (y * width + x) * bytesPerPixel
                //Take the RGB values from each pixel 0-255
                let red = CGFloat(rawData[pixelIndex])
                let green = CGFloat(rawData[pixelIndex + 1])
                let blue = CGFloat(rawData[pixelIndex + 2])
                //Apply the brightness formula by taking the average color intensity
                let brightness = (red + green + blue) / 3.0
                //Add the pixel's brightness to the total brightness
                totalBrightness += brightness
            }
        }
        //Divide by the number of pixels to find the average brightness
        let averageBrightness = totalBrightness / CGFloat(width * height)
        return averageBrightness
    }
    
    func consistentBrightness(image1: UIImage, image2: UIImage, tolerance: CGFloat = 10.0) -> (isConsistent: Bool, isExposureGood1: Bool, isExposureGood2: Bool) {
        let brightness1 = calculateBrightness(for: image1)
        let brightness2 = calculateBrightness(for: image2)
        //Absolute value of the brightness level difference
        let difference = abs(brightness1 - brightness2)
        
        let isConsistent = difference <= tolerance
        let isExposureGood1 = (10 <= brightness1 && brightness1 <= 245)
        let isExposureGood2 = (10 <= brightness2 && brightness2 <= 245)
        return (isConsistent, isExposureGood1, isExposureGood2)
    }
    
    func checkWhiteBalance(for image: UIImage) -> Bool {
        guard let rawData = extractPixelData(from: image) else { return false }
        
        let width = image.cgImage!.width
        let height = image.cgImage!.height
        let bytesPerPixel = 4
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0
        let pixelCount = width * height

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let red = CGFloat(rawData[pixelIndex])
                let green = CGFloat(rawData[pixelIndex + 1])
                let blue = CGFloat(rawData[pixelIndex + 2])
                
                totalRed += red
                totalGreen += green
                totalBlue += blue
            }
        }

        let avgRed = totalRed / CGFloat(pixelCount)
        let avgGreen = totalGreen / CGFloat(pixelCount)
        let avgBlue = totalBlue / CGFloat(pixelCount)

        let redGreenDiff = abs(avgRed - avgGreen)
        let redBlueDiff = abs(avgRed - avgBlue)
        let greenBlueDiff = abs(avgGreen - avgBlue)

        let tolerance: CGFloat = 15.0 // Adjust as needed
        return redGreenDiff <= tolerance && redBlueDiff <= tolerance && greenBlueDiff <= tolerance
    }
    
    private func extractPixelData(from image: UIImage) -> UnsafeMutablePointer<UInt8>? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * bytesPerPixel)
        
        guard let context = CGContext(data: rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            rawData.deallocate()
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        return rawData
    }
}

