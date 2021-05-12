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
    @Published private(set) var detectedPuzzles = [UUID: DetectedPuzzle]()
    @Published private(set) var capturedPreviewImage = UIImage()
    private var capturedCancellable: AnyCancellable? = nil
    
    private let capturedFramesSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private let videoDataOutputQueue = DispatchQueue(label: "com.JDM.videoDataOutputQueue")
    private let imageProcessingQueue = DispatchQueue(label: "com.JDM.imageProcessingQueue")
    private var visionModel: VNCoreMLModel? = nil
    private let rectangleDetector = RectangleDetector()
    private let digitDetector = DigitDetector()
    private let puzzleDetector = PuzzleDetector()
    //    private var trackedRectangles = [UUID : VNRectangleObservation]()
    
    
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
        connection.videoOrientation = .portrait
        connection.isEnabled = true
        session.startRunning()
    }
    
    private func processFrames(capturedFrame: CMSampleBuffer) {
        guard let imageBuffer = capturedFrame.imageBuffer else {
            return
        }
        detectedPuzzles.removeAll()
        let image = CIImage(cvPixelBuffer: imageBuffer)
        let detectedRectangles = rectangleDetector.detectRectangles(image: image)
        guard let detectedRectangle = detectedRectangles.first else {
            return
        }
        
        let cropRect = VNImageRectForNormalizedRect(detectedRectangle.value.boundingBox, Int(image.extent.width), Int(image.extent.height))
        let croppedImage = image.cropped(to: cropRect)
        let transform = CGAffineTransform.identity
            .translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
        //            capturedPreviewImage = UIImage(ciImage: croppedImage.transformed(by: transform))
        //            let visionModel = DigitDetector()
        digitDetector.detect(croppedImage.transformed(by: transform)) {
            detectedDigits in
            guard let detectedPuzzle = self.puzzleDetector.detect(digits: detectedDigits) else {
                return
            }
            let puzzle = Puzzle(puzzle: detectedPuzzle)
            let solvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: puzzle)
            if solvedPuzzle.isSolved() {
                print("puzzle is solved \(solvedPuzzle.puzzle)")
                self.imageProcessingQueue.async {
                    self.detectedPuzzles[detectedRectangle.key] =
                        DetectedPuzzle(rect: detectedRectangle.value, solvedPuzzle: solvedPuzzle.puzzle, unSolvedPuzzle: detectedPuzzle)
                }
            }
            else {
                print("puzzle not solved")
            }
        }
        capturedPreviewImage = digitDetector.croppedPreviewImage
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
    }
}

struct DetectedPuzzle {
    var rect: VNRectangleObservation
    var solvedPuzzle: [[Int]]?
    var unSolvedPuzzle: [[Int]]?
}
