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
    @Published private(set) var capturedPreviewImage = UIImage()
    private var capturedCancellable: AnyCancellable? = nil
    
    private let capturedFramesSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private let videoDataOutputQueue = DispatchQueue(label: "com.JDM.videoDataOutputQueue")
    private let stateMachine = StateMachine()
    
    override init() {
        
        super.init()
        capturedCancellable = capturedFramesSubject.subscribe(on: videoDataOutputQueue)
            .receive(on: stateMachine.stateMachineQueue)
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
    
    func getCurrentPuzzles() -> AnyPublisher<[UUID: DetectedPuzzle], Never> {
        return stateMachine.$currentDetectedPuzzles
        .eraseToAnyPublisher()
    }
    
    private func processFrames(capturedFrame: CMSampleBuffer) {
        guard let imageBuffer = capturedFrame.imageBuffer else {
            return
        }
        
        let image = CIImage(cvPixelBuffer: imageBuffer)
        stateMachine.eventHandler(event: .imageIn(image))
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
    
    struct DetectedPuzzle {
        var rect: VNRectangleObservation
        var solvedPuzzle: [[Int]]?
        var unSolvedPuzzle: [[Int]]?
    }
    
    class StateMachine {
        
        enum State {
            case detectingPuzzles
            case trackingPotentialPuzzles
            case trackingUnSolvedPuzzles
            case trackingSolvedPuzzles
        }
        enum Event {
            case imageIn(CIImage)
        }
        
        let stateMachineQueue = DispatchQueue(label: "com.JDM.stateMachineQueue")
        private var currentImage = CIImage()
        private var currentDetectedRectangles = [UUID : VNRectangleObservation]()
        @Published private(set) var currentDetectedPuzzles = [UUID: DetectedPuzzle]()
        private let rectangleDetector = RectangleDetector()
        private var digitDetector = DigitDetector()
        private var puzzleDetector = PuzzleDetector()
        private var currentState: State = .detectingPuzzles
        
        func eventHandler(event: Event) {
            switch event {
            case .imageIn(let image):
                currentImage = image
                currentDetectedRectangles = rectangleDetector.detectRectangles(image: image)
            }
            updateState()
        }
        
        private func updateState() {
            guard let currentDetectedRectangle = currentDetectedRectangles.first else {
                currentDetectedPuzzles = [UUID: DetectedPuzzle]()
                currentState = .detectingPuzzles
                return
            }
            switch currentState {
            case .detectingPuzzles:
                currentDetectedPuzzles = [currentDetectedRectangle.key: DetectedPuzzle(rect: currentDetectedRectangle.value, solvedPuzzle: nil, unSolvedPuzzle: nil)]
                currentState = .trackingPotentialPuzzles
            case .trackingPotentialPuzzles:
                guard let detectedPuzzle = currentDetectedPuzzles.first else {
                    print("unexpected State1")
//                    currentState = .detectingPuzzles
                    return
                }
                currentDetectedPuzzles = [detectedPuzzle.key: DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                             solvedPuzzle: detectedPuzzle.value.solvedPuzzle,
                                                                             unSolvedPuzzle: detectedPuzzle.value.unSolvedPuzzle)]
                guard detectedPuzzle.value.unSolvedPuzzle == nil else {
                    print("unexpected State2")
                    return
                }
                let cropRect = VNImageRectForNormalizedRect(detectedPuzzle.value.rect.boundingBox,
                                                            Int(currentImage.extent.width),
                                                            Int(currentImage.extent.height))
                let croppedImage = currentImage.cropped(to: cropRect)
                let transform = CGAffineTransform.identity
                    .translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
                
                digitDetector.detect(croppedImage.transformed(by: transform)) {
                    detectedDigits in
                    guard let puzzleDetectorResult = self.puzzleDetector.detect(digits: detectedDigits) else {
                        return
                    }
                    self.stateMachineQueue.sync {
                        self.currentDetectedPuzzles[detectedPuzzle.key] = DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                                         solvedPuzzle: detectedPuzzle.value.solvedPuzzle,
                                                                                     unSolvedPuzzle: puzzleDetectorResult)
                        self.currentState = .trackingUnSolvedPuzzles
                    }
                }
            case .trackingUnSolvedPuzzles:
                digitDetector = DigitDetector()
                puzzleDetector = PuzzleDetector()
                guard let detectedPuzzle = currentDetectedPuzzles.first else {
                    print("unexpected State3")
                    return
                }
                currentDetectedPuzzles = [detectedPuzzle.key: DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                             solvedPuzzle: detectedPuzzle.value.solvedPuzzle,
                                                                             unSolvedPuzzle: detectedPuzzle.value.unSolvedPuzzle)]
                guard let unsolvedPuzzle = detectedPuzzle.value.unSolvedPuzzle else {
                    print("unexpected State4.1")
                    return
                }
                guard detectedPuzzle.value.solvedPuzzle == nil else {
                    print("unexpected State4.2")
                    return
                }
                let solvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: Puzzle(puzzle: unsolvedPuzzle))
                if solvedPuzzle.isSolved() {
                    print("puzzle is solved \(solvedPuzzle.puzzle)")
                    currentDetectedPuzzles = [detectedPuzzle.key: DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                                 solvedPuzzle: solvedPuzzle.puzzle,
                                                                                 unSolvedPuzzle: detectedPuzzle.value.unSolvedPuzzle)]
                    currentState = .trackingSolvedPuzzles
                } else {
                    currentDetectedPuzzles = [detectedPuzzle.key: DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                                 solvedPuzzle: nil,
                                                                                 unSolvedPuzzle: nil)]
                    currentState = .trackingPotentialPuzzles
                    print("puzzle not solved")
                }
            case .trackingSolvedPuzzles:
                guard let detectedPuzzle = currentDetectedPuzzles.first else {
                    print("unexpected State5")
                    return
                }
                currentDetectedPuzzles = [detectedPuzzle.key: DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                                             solvedPuzzle: detectedPuzzle.value.solvedPuzzle,
                                                                             unSolvedPuzzle: detectedPuzzle.value.unSolvedPuzzle)]
            }
        }
    }
}


