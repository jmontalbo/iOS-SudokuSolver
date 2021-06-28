//
//  MainViewModelTests.swift
//  SudokuSolverTests
//
//  Created by Joe Montalbo on 6/17/21.
//

import Foundation
import AVFoundation
import XCTest
import Combine
@testable import SudokuSolver

class MainViewModelTests: XCTestCase {
    
    var stateMachineUnderTest: MainViewModel.StateMachine!
    var currentDetectedPuzzles: AnyCancellable!
    override func setUpWithError() throws {
        stateMachineUnderTest = MainViewModel.StateMachine()
    }
    
    func testStateMachineDetectsPuzzleInVideo() throws {
        let expectedSolvedPuzzle = [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
        ]
        var resultsReported = 0
        var puzzlesDetected = 0.0
        let testExpectation = expectation(description: "Received Detected Results")
        testExpectation.assertForOverFulfill = false
        currentDetectedPuzzles = stateMachineUnderTest.$currentDetectedPuzzles.sink {
            currentPuzzles in
            print("puzzles \(currentPuzzles)")
            resultsReported += 1
            guard let currentPuzzle = currentPuzzles.first else {
                return
            }
            guard let solvedPuzzle = currentPuzzle.value.solvedPuzzle else {
                return
            }
            if solvedPuzzle == expectedSolvedPuzzle {
                puzzlesDetected += 1.0
                if puzzlesDetected == 10.0 {              testExpectation.fulfill()
                }
            }
        }
        let fileString = Bundle(for: type(of: self)).path(forResource: "IMG_2745", ofType: "MOV")!
        let videoURL = URL(fileURLWithPath: fileString)
        let videoFile = AVAsset(url: videoURL)
        let videoReader = VideoReader(videoAsset: videoFile)!
        var framesIn = 0.0
        
        while let nextFrame = videoReader.nextFrame(){
            framesIn += 1.0
            let image = CIImage(cvPixelBuffer: nextFrame)
            stateMachineUnderTest.stateMachineQueue.sync {
                self.stateMachineUnderTest.eventHandler(event: .imageIn(image, orientation: videoReader.orientation))
            }
        }
        
        waitForExpectations(timeout: 10.0) {_ in
            let fractionDetected = puzzlesDetected/framesIn
            print("frames in = \(framesIn)")
            print("results reported = \(resultsReported)")
            print("puzzles detected = \(puzzlesDetected)")
            print("fraction detected = \(fractionDetected)")
            XCTAssertGreaterThan(fractionDetected, 0.5)
        }
    }
}
