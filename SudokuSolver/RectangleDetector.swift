//
//  RectangleDetector.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 5/12/21.
//

import Foundation
import Vision
import CoreImage

class RectangleDetector {
    
    private let rectangleDetectionRequest = VNDetectRectanglesRequest()
    private var rectangleTrackingRequest: VNTrackRectangleRequest? = nil
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    private var lastObservations: VNRectangleObservation? = nil
    
    func detectRectangles(image: CIImage) -> [UUID: VNRectangleObservation] {
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
            rectangleDetectionRequest.minimumSize = Float(0.8)
            rectangleDetectionRequest.maximumObservations = 1
            rectangleDetectionRequest.quadratureTolerance = 45
            request = rectangleDetectionRequest
        }
        
        do {
            try sequenceRequestHandler.perform([request], on: image)
        } catch {
            print("sequenceRequestHandler error \(error)")
            lastObservations = nil
        }
        guard let rectObservations = request.results as? [VNRectangleObservation] else {
            return [:]
        }
        var detectedRects = [UUID : VNRectangleObservation]()
        for rect in rectObservations {
            detectedRects[rect.uuid] = rect
            lastObservations = rect
        }
        print(detectedRects)
        return detectedRects
    }
}

