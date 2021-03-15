//
//  MainViewModel.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 3/4/21.
//

import AVFoundation
import Photos
import Vision
import Combine
import UIKit

class MainViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let session = AVCaptureSession()
    @Published private(set) var detectedPuzzles = [VNRectangleObservation]()
    @Published private(set) var capturedPreviewImage = UIImage()
    private var capturedCancellable: AnyCancellable? = nil
    
    private let capturedFramesSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private let videoDataOutputQueue = DispatchQueue(label: "com.JDM.videoDataOutputQueue")
    private let imageProcessingQueue = DispatchQueue(label: "com.JDM.imageProcessingQueue")
    
    override init() {
        super.init()
        capturedCancellable = capturedFramesSubject.subscribe(on: videoDataOutputQueue)
            .receive(on: imageProcessingQueue)
            .sink(receiveValue: processFrames)
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Video Device was nil:")
            return
        }
        let videoDeviceInput: AVCaptureDeviceInput
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Error creating device input from video device: \(error).")
            return
        }
        
        guard session.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to capture session.")
            return
        }
        
        session.addInput(videoDeviceInput)
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        guard session.canAddOutput(videoDataOutput) else {
            print("Could not add video data output to capture session.")
            return
        }
        
        session.addOutput(videoDataOutput)
        guard let connection = videoDataOutput.connection(with: AVMediaType.video) else {
            print("Could not establish output connection")
            return
        }
        connection.isEnabled = true
        session.startRunning()
    }
    
    private func processFrames(capturedFrame: CMSampleBuffer) {
        guard let imageBuffer = capturedFrame.imageBuffer else {
            return
        }
        let image = CIImage(cvPixelBuffer: imageBuffer)
        let rotatedImage = image.oriented(.right)
        let imageRequestHandler = VNImageRequestHandler(ciImage: rotatedImage, options: [:])
        let rectangleDetectionRequest = VNDetectRectanglesRequest()
        //        rectangleDetectionRequest.minimumConfidence = VNConfidence(0.8)
        rectangleDetectionRequest.minimumAspectRatio = VNAspectRatio(0.95)
        rectangleDetectionRequest.maximumAspectRatio = VNAspectRatio(1.05)
        rectangleDetectionRequest.minimumSize = Float(0.3)
        rectangleDetectionRequest.maximumObservations = Int(10)
        
        do {
            try imageRequestHandler.perform([rectangleDetectionRequest])
        } catch {
            print("imageRequestHandler error")
        }
        
        if let rectObservations = rectangleDetectionRequest.results as? [VNRectangleObservation],
           let firstRectObservation = rectObservations.first {
            detectedPuzzles = rectObservations
            let cropRect = VNImageRectForNormalizedRect(firstRectObservation.boundingBox, Int(rotatedImage.extent.width), Int(rotatedImage.extent.height))
            let croppedImage = rotatedImage.cropped(to: cropRect)
            let transform = CGAffineTransform.identity
                .translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
            capturedPreviewImage = UIImage(ciImage: croppedImage.transformed(by: transform))
            
//            let request = VNRecognizeTextRequest()
            let request = VNDetectTextRectanglesRequest()
            request.reportCharacterBoxes = true
//            request.recognitionLevel = .fast
//            request.usesLanguageCorrection = false
            let croppedImageRequestHandler = VNImageRequestHandler(ciImage: croppedImage.transformed(by: transform), options: [:])
            do {
                try croppedImageRequestHandler.perform([request])
            } catch {
                print("imageRequestHandler error")
            }
            if let textObservations = request.results as? [VNTextObservation] {
                print(textObservations.count)
//                for observation in textObservations {
//                    print(observation.characterBoxes)
//                }
            }
            else {
                print("No Observations"   )
            }
        }
        else {
            print("observation is nil")
        }
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        var copySampleBuffer: CMSampleBuffer?
        let error = CMSampleBufferCreateCopy(allocator: nil, sampleBuffer: sampleBuffer, sampleBufferOut: &copySampleBuffer)
        if error == noErr {
            capturedFramesSubject.send(copySampleBuffer!)
        }
        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
//        print("Sample Buffer Dropped.")
    }
    
}
