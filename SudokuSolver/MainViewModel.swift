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
            case imageIn(CIImage, orientation: CGImagePropertyOrientation = .up)
        }
        
        let stateMachineQueue = DispatchQueue(label: "com.JDM.stateMachineQueue")
        private var currentImage = CIImage()
        @Published private(set) var currentDetectedPuzzles = [UUID: DetectedPuzzle]()
        private let rectangleDetector = RectangleDetector()
        private var digitDetector = DigitDetector()
        private var puzzleDetector = PuzzleDetector()
        private var currentState: State = .detectingPuzzles
        
        func eventHandler(event: Event) {
            switch event {
            case .imageIn(let image, let orientation):
                currentImage = image.oriented(orientation)
                let currentDetectedRectangles = rectangleDetector.detectRectangles(image: currentImage, orientation: .up)
                guard let currentDetectedRectangle = currentDetectedRectangles.first else {
                    currentDetectedPuzzles = [UUID: DetectedPuzzle]()
                    updateState()
                    return
                }
                if currentDetectedPuzzles.isEmpty {
                    currentDetectedPuzzles = [currentDetectedRectangle.key:
                                                DetectedPuzzle(rect: currentDetectedRectangle.value,
                                                               solvedPuzzle: nil,
                                                               unSolvedPuzzle: nil)]
                }
                guard var currentDetectedPuzzle = currentDetectedPuzzles.first else {
                    assertionFailure("No detected puzzle after empty check")
                    return
                }
                currentDetectedPuzzle.value.rect = currentDetectedRectangle.value
                currentDetectedPuzzles = [currentDetectedPuzzle.key: currentDetectedPuzzle.value]
                switch currentState {
                case .trackingPotentialPuzzles:
                    currentDetectedPuzzle.value.solvedPuzzle = nil
                    currentDetectedPuzzle.value.unSolvedPuzzle = nil
                    currentDetectedPuzzles = [currentDetectedPuzzle.key: currentDetectedPuzzle.value]
                    let cropRect = VNImageRectForNormalizedRect(currentDetectedPuzzle.value.rect.boundingBox,
                                                                Int(currentImage.extent.width),
                                                                Int(currentImage.extent.height))
                    let croppedImage = currentImage.cropped(to: cropRect)
                    let croppedTransform = CGAffineTransform.identity
                        .translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
                    let detectedDigits = digitDetector.detect(croppedImage.transformed(by: croppedTransform), orientation: .up)
                    guard self.currentState == .trackingPotentialPuzzles else {
                        print("not setting currentUnsolvedPuzzle during \(self.currentState)")
                        return
                    }
                    guard let puzzleDetectorResult = self.puzzleDetector.detect(digits: detectedDigits) else {
                        return
                    }
                    
                    guard var detectedPuzzleToUpdate = self.currentDetectedPuzzles.first else {
                        return
                    }
                    detectedPuzzleToUpdate.value.unSolvedPuzzle = puzzleDetectorResult
                    self.currentDetectedPuzzles = [detectedPuzzleToUpdate.key: detectedPuzzleToUpdate.value]
                    
                case .trackingUnSolvedPuzzles:
                    guard let unsolvedPuzzle = currentDetectedPuzzle.value.unSolvedPuzzle else {
                        print("unexpected State expected non-nil unsolved puzzle while trying to solve puzzle")
                        return
                    }
//                    guard currentDetectedPuzzle.value.solvedPuzzle == nil else {
//                        print("unexpected State expected non-nil unsolved puzzle while trying to solve puzzle")
//                        return
//                    }
                    let solvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: Puzzle(puzzle: unsolvedPuzzle))
                    if solvedPuzzle.isSolved() {
                        currentDetectedPuzzle.value.solvedPuzzle = solvedPuzzle.puzzle
                        currentDetectedPuzzles = [currentDetectedPuzzle.key: currentDetectedPuzzle.value]
                        print("puzzle is solved \(solvedPuzzle.puzzle)")

                    } else {
                        currentDetectedPuzzle.value.solvedPuzzle = nil
                        currentDetectedPuzzle.value.unSolvedPuzzle = nil
                        currentDetectedPuzzles = [currentDetectedPuzzle.key: currentDetectedPuzzle.value]
                        print("puzzle not solved")
                    }
                default:
                    break
                }

            }
            updateState()
        }
        
        private func updateState() {
            let previousState = currentState
            guard let currentDetectedPuzzle = currentDetectedPuzzles.first else {
                currentState = .detectingPuzzles
                if currentState != previousState {
                    digitDetector = DigitDetector()
                    puzzleDetector = PuzzleDetector()
                    print("State transition:\(previousState) to \(currentState)")
                }
                return
            }
            switch currentState {
            case .detectingPuzzles:
                currentState = .trackingPotentialPuzzles
            case .trackingPotentialPuzzles:
                if currentDetectedPuzzle.value.unSolvedPuzzle != nil {
                    digitDetector = DigitDetector()
                    puzzleDetector = PuzzleDetector()
                    currentState = .trackingUnSolvedPuzzles
                }
            case .trackingUnSolvedPuzzles:
                if currentDetectedPuzzle.value.solvedPuzzle != nil {
                    currentState = .trackingSolvedPuzzles
                } else {
                    currentState = .trackingPotentialPuzzles
                }
            default :
                break
            }
            if currentState != previousState {
                print("State transition:\(previousState) to \(currentState)")
            }
        }
    }
}
