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

class MainViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let session = AVCaptureSession()
    @Published private(set) var detectedPuzzles = [VNRectangleObservation]()
    private var capturedCancellable: AnyCancellable? = nil

    @Published private var capturedFrames = [CMSampleBuffer]()
    private let videoDataOutputQueue = DispatchQueue(label: "com.JDM.videoDataOutputQueue")
    private let imageProcessingQueue = DispatchQueue(label: "com.JDM.imageProcessingQueue")
    
    override init() {
        super.init()
        capturedCancellable = $capturedFrames.subscribe(on: videoDataOutputQueue)
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
    
    private func processFrames(capturedFrames: [CMSampleBuffer]) {
        for frame in capturedFrames {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.imageBuffer!, orientation: .up, options: [:]) // look at orientation details and handle nil sampleBuffer
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
            
            if let rectObservations = rectangleDetectionRequest.results as? [VNRectangleObservation] {
                detectedPuzzles = rectObservations
                for observation in rectObservations {
                    print(observation)
                }
            }
            else {
                print("observation is nil")
            }
        }
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        capturedFrames = [sampleBuffer]
//        capturedFrames.append(sampleBuffer)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        print("Sample Buffer Dropped.")
    }
    
}
