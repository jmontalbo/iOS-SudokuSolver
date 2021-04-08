//
//  DigitDetector.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 3/21/21.
//

import Foundation
import Vision
import UIKit
import MLKitTextRecognition
import MLKitVision


class DigitDetector {
    
    public var croppedPreviewImage = UIImage()
    private let textRecognizer = TextRecognizer.textRecognizer()
    
    public func detect(_ image: CIImage, completionHandler: @escaping ([DigitDetectorResult]) -> ()) {
        let context = CIContext()
        let cgImage = context.createCGImage(image, from: image.extent)
        let fixedCroppedUIImage = UIImage(cgImage: cgImage!)
        croppedPreviewImage = fixedCroppedUIImage
        let fixedCroppedVisionImage = VisionImage(image: fixedCroppedUIImage)
        fixedCroppedVisionImage.orientation = fixedCroppedUIImage.imageOrientation
        textRecognizer.process(fixedCroppedVisionImage) { result, error in
            guard error == nil, let result = result else {
                // Error handling
                return
            }
            var digitDetectorResults = [DigitDetectorResult]()
            for block in result.blocks {
                for line in block.lines {
                    for element in line.elements {
                        let origin = element.cornerPoints[0].cgPointValue
                        let detectorResult = DigitDetectorResult(
                            row: Int(9.0 * ((origin.y / image.extent.height) + 0.02)),
                            column: Int(9.0 * ((origin.x / image.extent.width) + 0.02)),
                            digit: element.text
                        )
                        digitDetectorResults.append(detectorResult)
                        print("element \(detectorResult.digit) \(detectorResult.row) \(detectorResult.column)")
                    }
                }
            }
            completionHandler(digitDetectorResults)
        }
    }
}

struct DigitDetectorResult {
    let row: Int
    let column: Int
    let digit: String
}
