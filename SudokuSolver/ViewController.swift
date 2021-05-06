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
import Combine

class ViewController: UIViewController {
    
    private let mainViewModel = MainViewModel()
    private let previewView = VideoPreviewView()
    private let capturedView = UIImageView()
    private var showCancellable: AnyCancellable? = nil
    private var setPreviewImageCancellable: AnyCancellable? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        previewView.session = mainViewModel.session
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        capturedView.contentMode = .scaleToFill
        capturedView.backgroundColor = .black
        capturedView.isHidden = true // make false to see capturedView for debug
        view.addSubview(capturedView)
        capturedView.translatesAutoresizingMaskIntoConstraints = false
        capturedView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        capturedView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        capturedView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        capturedView.heightAnchor.constraint(equalTo: capturedView.widthAnchor).isActive = true

        showCancellable = mainViewModel.$detectedPuzzles.receive(on: DispatchQueue.main)
            .sink(receiveValue: show)
        
        setPreviewImageCancellable = mainViewModel.$capturedPreviewImage.receive(on: DispatchQueue.main)
            .sink(receiveValue: setPreviewImage)
    }
    
    private func show(puzzles: [DetectedPuzzle]) {
        previewView.show(puzzles: puzzles)
    }
    
    private func setPreviewImage(image: UIImage) {
        capturedView.image = image
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    @objc func orientationChanged() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            previewView.videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            previewView.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
        case .portrait:
            previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
        default:
            break
        }
    }
}
