//
//  ViewController.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 2/25/21.
//

import UIKit
import AVFoundation
import Photos
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let videoDataOutputQueue = DispatchQueue(label: "com.JDM.videoDataOutputQueue") //DispatchQueue establishes separate thread
    private let session = AVCaptureSession()
    private let previewView = VideoPreviewView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        previewView.session = session
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        session.sessionPreset = AVCaptureSession.Preset.vga640x480

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
        
        videoDataOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String : Int(videoDataOutput.availableVideoPixelFormatTypes[0]) ]
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    @objc func orientationChanged() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            previewView.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewView.videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
        case .portrait:
            previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
        default:
            break
        }
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: sampleBuffer.imageBuffer!, orientation: .up, options: [:]) // look at orientation details and handle nil sampleBuffer
        let rectangleDetectionRequest = VNDetectRectanglesRequest()
//        rectangleDetectionRequest.minimumConfidence = VNConfidence(0.8)
        rectangleDetectionRequest.minimumAspectRatio = VNAspectRatio(0.2)
        rectangleDetectionRequest.maximumAspectRatio = VNAspectRatio(1.0)
        rectangleDetectionRequest.minimumSize = Float(0.2)
        rectangleDetectionRequest.maximumObservations = Int(10)
        
        do {
            try imageRequestHandler.perform([rectangleDetectionRequest])
        } catch {
            print("imageRequestHandler error")
        }

        if let rectObservations = rectangleDetectionRequest.results as? [VNRectangleObservation] {
            for observation in rectObservations {
                print(observation)
            }
        }
        else {
            print("observation is nil")
        }
//        let sampleBufferCopy = buffer.deepCopy()
//        print("Video buffer \(sampleBuffer).")
    }

    func captureOutput(_ captureOutput: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        print("Sample buffer dropped.")
    }

}


