//
//  RectangleDetector.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 5/12/21.
//

import Foundation
import Vision
import CoreImage
import Accelerate

class RectangleDetector {
    
    private let rectangleDetectionRequest = VNDetectRectanglesRequest()
    private var rectangleTrackingRequest: VNTrackRectangleRequest? = nil
    private var sequenceRequestHandler: VNSequenceRequestHandler? = nil
    private var lastObservations: VNRectangleObservation? = nil
    private var lastReturnedObservation: VNRectangleObservation? = nil
    private var failedSubsequentObservations = 0
    
    func detectRectangles(image: CIImage, orientation: CGImagePropertyOrientation = .up) -> [UUID: VNRectangleObservation] {
        let filteredImage = filterImage(image: image)
        let request: VNRequest
        if let lastObservations = lastObservations {
            if rectangleTrackingRequest == nil {
                rectangleTrackingRequest = VNTrackRectangleRequest(rectangleObservation: lastObservations)
            }
            rectangleTrackingRequest!.inputObservation = lastObservations
            request = rectangleTrackingRequest!
        } else {
            //let rectangleDetectionRequest = VNDetectRectanglesRequest()
            //rectangleDetectionRequest.minimumConfidence = VNConfidence(0.8)
            rectangleDetectionRequest.minimumAspectRatio = VNAspectRatio(0.95)
            rectangleDetectionRequest.maximumAspectRatio = VNAspectRatio(1.05)
            rectangleDetectionRequest.minimumSize = Float(0.6)
            rectangleDetectionRequest.maximumObservations = 1
            rectangleDetectionRequest.quadratureTolerance = 5
            request = rectangleDetectionRequest
        }
        
        if sequenceRequestHandler == nil {
            sequenceRequestHandler = VNSequenceRequestHandler()
        }
        do {
            try sequenceRequestHandler!.perform([request], on: filteredImage, orientation: orientation)
        } catch {
            print("sequenceRequestHandler error \(error)")
            failedSubsequentObservations += 1
            if failedSubsequentObservations > 5 {
                failedSubsequentObservations = 0
                lastReturnedObservation = nil
            }
            lastObservations = nil
            sequenceRequestHandler = nil
        }
        guard let rectObservations = request.results as? [VNRectangleObservation] else {
//            failedSubsequentObservations += 1
            if let lastReturnedObservation = lastReturnedObservation {
                return [lastReturnedObservation.uuid: lastReturnedObservation]
            } else {
                return [:]
            }
        }
        failedSubsequentObservations = 0
        var detectedRects = [UUID : VNRectangleObservation]()
        for rect in rectObservations {
            detectedRects[rect.uuid] = rect
            lastObservations = rect
            lastReturnedObservation = rect
        }
//        print(detectedRects)
        return detectedRects
    }
    
    private func filterImage (image: CIImage) -> CIImage {

        let edgeFilter = CIFilter(name: "CIEdges")
        edgeFilter?.setValue(image, forKey: "inputImage")
        edgeFilter?.setValue(1.0, forKey: "inputIntensity")
        return edgeFilter!.outputImage!
    }
}

