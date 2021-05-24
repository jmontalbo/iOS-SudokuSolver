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
        return stateMachine.$currentState.map { (currentState) -> [UUID: DetectedPuzzle] in
            switch currentState {
            case .detectingPuzzles:
                return [:]
            case .trackingPotentialPuzzles(let potentialPuzzles):
                return potentialPuzzles
            case .trackingUnSolvedPuzzles(let unSolvedPuzzles):
                return unSolvedPuzzles
            case .trackingSolvedPuzzles(let solvedPuzzles):
                return solvedPuzzles
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func processFrames(capturedFrame: CMSampleBuffer) {
        guard let imageBuffer = capturedFrame.imageBuffer else {
            return
        }
        
        let image = CIImage(cvPixelBuffer: imageBuffer)
        stateMachine.handleEvent(event: .imageIn(image))
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
            case trackingPotentialPuzzles([UUID: DetectedPuzzle])
            case trackingUnSolvedPuzzles([UUID: DetectedPuzzle])
            case trackingSolvedPuzzles([UUID: DetectedPuzzle])
        }
        enum Event {
            case imageIn(CIImage)
            case rectangleFound(CIImage, [UUID : VNRectangleObservation])
            case rectangleNotFound
        }
        
        let stateMachineQueue = DispatchQueue(label: "com.JDM.stateMachineQueue")
        private let rectangleDetector = RectangleDetector()
        private var digitDetector = DigitDetector()
        private var puzzleDetector = PuzzleDetector()
        @Published private(set) var currentState: State = .detectingPuzzles
        
        func handleEvent(event: Event) {
//            print("state \(currentState )")
            switch event {
            case .imageIn(let image):
                let detectedRectangles = rectangleDetector.detectRectangles(image: image)
                if !detectedRectangles.isEmpty {
                    handleEvent(event: .rectangleFound(image, detectedRectangles))
                } else {
//                    digitDetector = DigitDetector()
//                    puzzleDetector = PuzzleDetector()
                    handleEvent(event: .rectangleNotFound)
                }
            case .rectangleFound(let image, let detectedRectangles):
                let detectedRectangle = detectedRectangles.first!.value
                switch currentState {
                case .detectingPuzzles:
                    var detectedPuzzles = [UUID:DetectedPuzzle]()
                    detectedPuzzles[detectedRectangles.first!.key] = DetectedPuzzle(rect: detectedRectangle, solvedPuzzle: nil, unSolvedPuzzle: nil)
                    currentState = .trackingPotentialPuzzles(detectedPuzzles)
//                    handleEvent(event: .rectangleFound(image, detectedRectangles))
                case .trackingPotentialPuzzles(var detectedPuzzles):
                    let detectedPuzzle = detectedPuzzles.first!.value
                    detectedPuzzles[detectedPuzzles.first!.key] = DetectedPuzzle(rect: detectedRectangle,
                                                                                 solvedPuzzle: detectedPuzzle.solvedPuzzle,
                                                                                 unSolvedPuzzle: detectedPuzzle.unSolvedPuzzle)
                    currentState = .trackingPotentialPuzzles(detectedPuzzles)
                    
                    let cropRect = VNImageRectForNormalizedRect(detectedPuzzle.rect.boundingBox, Int(image.extent.width), Int(image.extent.height))
                    let croppedImage = image.cropped(to: cropRect)
                    let transform = CGAffineTransform.identity
                        .translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
                    
                    digitDetector.detect(croppedImage.transformed(by: transform)) {
                        detectedDigits in
                        guard let puzzleDetectorResult = self.puzzleDetector.detect(digits: detectedDigits) else {
                            return
                        }
                        self.stateMachineQueue.sync {
                            detectedPuzzles[detectedPuzzles.first!.key] = DetectedPuzzle(rect: detectedRectangle,
                                                                                         solvedPuzzle: detectedPuzzle.solvedPuzzle,
                                                                                         unSolvedPuzzle: puzzleDetectorResult)
                            switch self.currentState {
                            case .trackingUnSolvedPuzzles, .trackingSolvedPuzzles:
                                return
                            case .trackingPotentialPuzzles:
                                self.currentState = .trackingUnSolvedPuzzles(detectedPuzzles)
                            default:
                                print("Unexpected State \(self.currentState)")
                                break
                            }
                        }
                    }
                case .trackingUnSolvedPuzzles(var detectedPuzzles):
                    let detectedPuzzle = detectedPuzzles.first!.value
                    detectedPuzzles[detectedPuzzles.first!.key] = DetectedPuzzle(rect: detectedRectangle,
                                                                                 solvedPuzzle: detectedPuzzle.solvedPuzzle,
                                                                                 unSolvedPuzzle: detectedPuzzle.unSolvedPuzzle)
                    currentState = .trackingSolvedPuzzles(detectedPuzzles)
                    let solvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: Puzzle(puzzle: detectedPuzzle.unSolvedPuzzle!))
                    if solvedPuzzle.isSolved() {
                        print("puzzle is solved \(solvedPuzzle.puzzle)")
                        detectedPuzzles[detectedPuzzles.first!.key] = DetectedPuzzle(rect: detectedRectangle,
                                                                                     solvedPuzzle: solvedPuzzle.puzzle,
                                                                                     unSolvedPuzzle: detectedPuzzle.unSolvedPuzzle)
                        currentState = .trackingSolvedPuzzles(detectedPuzzles)
                    } else {
                        currentState = .trackingPotentialPuzzles(detectedPuzzles)
                        print("puzzle not solved")
                    }
//                    handleEvent(event: .rectangleFound(image, detectedRectangles))
                case .trackingSolvedPuzzles(var detectedPuzzles):
                    let detectedPuzzle = detectedPuzzles.first!.value
                    detectedPuzzles[detectedPuzzles.first!.key] = DetectedPuzzle(rect: detectedRectangle,
                                                                                 solvedPuzzle: detectedPuzzle.solvedPuzzle,
                                                                                 unSolvedPuzzle: detectedPuzzle.unSolvedPuzzle)
                    currentState = .trackingSolvedPuzzles(detectedPuzzles)
                }
            case .rectangleNotFound:
                switch currentState {
                case .detectingPuzzles:
                    break
                default:
                    puzzleDetector = PuzzleDetector()
                    digitDetector = DigitDetector()
                }
                currentState = .detectingPuzzles
            }
        }
    }
}


