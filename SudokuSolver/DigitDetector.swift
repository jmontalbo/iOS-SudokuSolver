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
    private var rawDigitHistory = [[DigitDetectorResult]]()
    
    public func detect(_ image: CIImage,
                       orientation: CGImagePropertyOrientation) -> [DigitDetectorResult] {
        let context = CIContext()
        let cgImage = context.createCGImage(image, from: image.extent)
        let fixedCroppedUIImage = UIImage(cgImage: cgImage!)
        croppedPreviewImage = fixedCroppedUIImage
        let fixedCroppedVisionImage = VisionImage(image: fixedCroppedUIImage)
        fixedCroppedVisionImage.orientation = DigitDetector.getOrientation(from: orientation)  //fixedCroppedUIImage.imageOrientation
        do {
            let result = try textRecognizer.results(in: fixedCroppedVisionImage)
            guard
                image.extent.height > 0.0,
                image.extent.width > 0.0,
                image.extent.height.isFinite,
                image.extent.width.isFinite,
                !image.extent.height.isNaN,
                !image.extent.width.isNaN
            else {
                // Error handling
                return []
            }
            var rawDigitDetectorResults = [DigitDetectorResult]()
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
                            guard let digit = Int(String(character)) else {
                                continue
                            }
                            let detectorResult = DigitDetectorResult(
                                row: row,
                                column: column,
                                digit: digit
                            )
                            rawDigitDetectorResults.append(detectorResult)
                            column = column + 1
                        }
                    }
                }
            }
            self.rawDigitHistory.append(rawDigitDetectorResults)
            if self.rawDigitHistory.count > 5 {
                self.rawDigitHistory.remove(at: 0)
            }
            var digitVotes = [DigitDetectorResult:Int]()
            for rawDigitHistoryEntry in self.rawDigitHistory {
                for rawDigit in rawDigitHistoryEntry {
                    guard let currentDigitVotes = digitVotes[rawDigit] else {
                        digitVotes[rawDigit] = 1
                        continue
                    }
                    digitVotes[rawDigit] =  currentDigitVotes + 1
                }
            }
            var digitDetectorResults = [DigitDetectorResult]()
            for (digitDetectorResult, votes) in digitVotes {
                if votes > 2 {
                    digitDetectorResults.append(digitDetectorResult)
                }
            }
            print(digitDetectorResults.count)
            //            print(digitVotes)
            return digitDetectorResults
        } catch {
            print("digit detector failure \(error)")
            return []
        }
    }
    
    private static func getOrientation(from: CGImagePropertyOrientation) -> UIImage.Orientation {
        switch from {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        case .left:
            return .left
        }
    }
}



struct DigitDetectorResult: Hashable {
    let row: Int
    let column: Int
    let digit: Int
}
