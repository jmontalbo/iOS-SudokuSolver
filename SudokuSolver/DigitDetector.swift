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
            guard
                error == nil,
                let result = result,
                image.extent.height > 0.0,
                image.extent.width > 0.0,
                image.extent.height.isFinite,
                image.extent.width.isFinite,
                !image.extent.height.isNaN,
                !image.extent.width.isNaN
                else {
                // Error handling
                return
            }
            var digitDetectorResults = [DigitDetectorResult]()
            for block in result.blocks {
                for line in block.lines {
                    for element in line.elements {
                        let filteredText = element.text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                                    .joined()
                        if filteredText.count == 0 {
                            continue
                        }
                        let center = CGPoint(
                            x: element.frame.origin.x + element.frame.size.width /
                                (2.0 * CGFloat(filteredText.count)),
                            y: element.frame.midY)
                        let row = Int(9.0 * ((center.y / image.extent.height)))
                        var column = Int(9.0 * ((center.x / image.extent.width)))
                        for character in filteredText {
                            let detectorResult = DigitDetectorResult(
                                row: row,
                                column: column,
                                digit: String(character)
                            )
                            digitDetectorResults.append(detectorResult)
//                            print("element \(detectorResult.digit) \(detectorResult.row) \(detectorResult.column) element.text \(element.text) frame \(element.frame) midX \(element.frame.midX) midY \(element.frame.midY) extent \(image.extent)")
                            column = column + 1
                        }

                    }
                }
            }
            print(digitDetectorResults.count)
            completionHandler(digitDetectorResults)
        }
    }
}

struct DigitDetectorResult {
    let row: Int
    let column: Int
    let digit: String
}
