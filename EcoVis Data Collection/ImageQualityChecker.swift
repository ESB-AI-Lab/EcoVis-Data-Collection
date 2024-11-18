//
//  ImageQualityChecker.swift
//  EcoVis Data Collection
//
//  Created by Kan on 11/3/24.
//
import UIKit
import CoreImage

class ImageQualityChecker {
    private let blurThreshold: Float = 1000.0 //Needs testing
    
    func performBlurrinessCheck(for image: UIImage) -> Bool{
        guard let cgImage = image.cgImage else { return false }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        let laplacianKernelString = """
        // Define a kernel function that applies a Laplacian filter to an image
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
               guard let laplacianKernel = CIColorKernel(source: laplacianKernelString) else { return false }
               
               // Apply the kernel to the image
               guard let outputImage = laplacianKernel.apply(extent: ciImage.extent, arguments: [ciImage]) else {
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
}
