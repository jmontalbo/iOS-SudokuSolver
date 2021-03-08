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
    private var showCancellable: AnyCancellable? = nil
    
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
        showCancellable = mainViewModel.$detectedPuzzles.sink(receiveValue: show)
    }
    
    private func show(puzzles: [VNRectangleObservation]) {
        previewView.show(rectangles: puzzles)
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
}
