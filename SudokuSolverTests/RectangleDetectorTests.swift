//
//  RectangleDetectorTests.swift
//  SudokuSolverTests
//
//  Created by Joe Montalbo on 5/16/21.
//

import Foundation
import XCTest
import AVFoundation
@testable import SudokuSolver

class RectangleDetectorTests: XCTestCase {
    
    override func setUpWithError() throws {
        //        detectorUnderTest = DigitDetector()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDetectorCanDetectRectangles() throws {
        let fileString = Bundle(for: type(of: self)).path(forResource: "IMG_2745", ofType: "MOV")!
        let videoURL = URL(fileURLWithPath: fileString)
        let videoFile = AVAsset(url: videoURL)
        let videoReader = VideoReader(videoAsset: videoFile)!
        
        let detectorUnderTest = RectangleDetector()
        var didDetectRectangle = false
        var framesIn = 0.0
        var rectsDetected = 0.0
        while let nextFrame = videoReader.nextFrame(){
            framesIn += 1.0
            let image = CIImage(cvPixelBuffer: nextFrame)
            let detectedRectangles = detectorUnderTest.detectRectangles(image: image, orientation: videoReader.orientation)
            if !detectedRectangles.isEmpty {
                rectsDetected += 1.0
                didDetectRectangle = true
            }
        }
        print("percent detected = \(rectsDetected/framesIn * 100.0)")
        XCTAssertTrue(didDetectRectangle)
    }
}
