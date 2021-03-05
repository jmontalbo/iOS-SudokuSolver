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

class ViewController: UIViewController, MainViewModelDelegate {
    
    private let mainViewModel = MainViewModel()
    private let previewView = VideoPreviewView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainViewModel.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        previewView.session = mainViewModel.session
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
    
    // MARK: MainViewModelDelegate
    func didDetectPuzzles(viewModel: MainViewModel, puzzles: [VNRectangleObservation]) {
        var rectangles = [CGRect]()
        for puzzle in puzzles{
            rectangles.append(puzzle.boundingBox)
        }
        previewView.show(rectangles: rectangles)
    }
}


