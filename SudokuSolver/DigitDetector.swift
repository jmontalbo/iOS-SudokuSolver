//
//  DigitDetector.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 3/21/21.
//

import Foundation
import Vision
import UIKit

class DigitDetector {
    
    public var croppedPreviewImage = UIImage()
    let detector: VNCoreMLModel!
    static let sizeROI = CGSize(width: 1.0/9.0 * 0.9, height: 1.0/9.0 * 0.9)
    static let singleROI = CGRect(origin: CGPoint(x: 0.03, y: 0.03), size: sizeROI)
    static let gridROIs = { () -> [CGRect] in
        var gridROIs = [CGRect]()
        for i in 0...8 {
            for j in 0...8 {
                gridROIs.append(
                    CGRect(origin:
                            CGPoint(
                                x: Double(i)/9.0 + 0.01,
                                y: Double(j)/9.0 + 0.01
                            ),
                           size: sizeROI
                    )
                )
            }
        }
        return gridROIs
    }()
    
    init() {
        guard let mlModel = try? MNIST(configuration: .init()).model,
              let detector = try? VNCoreMLModel(for: mlModel) else {
            print("Failed to load detector!")
            self.detector = nil
            return
        }
        self.detector = detector
    }
    
    public func detect(_ image: CIImage) -> [DigitDetectorResult] {
        let fixedImage = image.oriented(CGImagePropertyOrientation.downMirrored)
        let imageRequestHandler = VNImageRequestHandler(ciImage: fixedImage, orientation: .up, options: [:])
        do {
            let cropRect = VNImageRectForNormalizedRect(DigitDetector.singleROI,
                                                        Int(fixedImage.extent.width),
                                                        Int(fixedImage.extent.height))
            let croppedImage = fixedImage.cropped(to: cropRect)
            let transform = CGAffineTransform.identity
                .translatedBy(x: -cropRect.origin.x,
                              y: -cropRect.origin.y)
            croppedPreviewImage = UIImage(ciImage: croppedImage.transformed(by: transform))
            var digits = [DigitDetectorResult]()
            for singleCellROI in [DigitDetector.singleROI] {
                let mlRequest = VNCoreMLRequest(model: detector)
                mlRequest.regionOfInterest = singleCellROI
                try imageRequestHandler.perform([mlRequest])
                if let textObservations = mlRequest.results as? [VNClassificationObservation] {
                    var highestConfidenceTextObservation: VNClassificationObservation? = nil
                    for textObservation in textObservations {
                        if let highestConfidenceObservation = highestConfidenceTextObservation {
                            if textObservation.confidence > highestConfidenceObservation.confidence {
                                highestConfidenceTextObservation = textObservation
                            }
                        }
                        else {
                            highestConfidenceTextObservation = textObservation
                        }
                    }
                    if let highestConfidenceObservation = highestConfidenceTextObservation,
                       highestConfidenceObservation.confidence > 0.9 {
                        let result = DigitDetectorResult(
                            row: Int(9.0 * singleCellROI.origin.x),
                            column: Int(9.0 * singleCellROI.origin.y),
                            digit: highestConfidenceObservation.identifier
                        )
                        digits.append(result)
                    }
                }
            }
            return digits
            
        } catch {
            print("imageRequestHandler error")
        }
            
            
//        do {
//            let request = VNCoreMLRequest(model: detector)
//            try imageRequestHandler.perform([request])
//            if let textObservations = request.results as? [VNRecognizedObjectObservation] {
//                var digits = [CGRect]()
//                for observation in textObservations {
//                    if observation.confidence > 0.1 {
//                        digits.append(observation.boundingBox)
//                        print("Observed \(observation.labels[0]) with confidence \(observation.confidence)")
//                    }
//                }
//                return digits
//            }
//            else {
//                print("No digit Observations")
//            }
//        } catch {
//            print("imageRequestHandler error")
//        }
        return []
    }
}

struct DigitDetectorResult {
    let row: Int
    let column: Int
    let digit: String
}
