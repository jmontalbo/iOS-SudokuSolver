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
    let testQueue = DispatchQueue.global(qos: .background)
    override func setUpWithError() throws {
        stateMachineUnderTest = MainViewModel.StateMachine()
    }
    
    func testStateMachineDetectsMedMovementEasyPuzzle() {
        runTest(videoFilename: "MedMovementEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func testStateMachineDetectsLittleMovementEasyPuzzle() {
        runTest(videoFilename: "LittleMovementEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
 
    func testStateMachineDetectsMedPuzzleToughBack() {
        runTest(videoFilename: "MedPuzzleToughBack", expectedSolvedPuzzle: [
            [8,1,2,7,5,3,6,4,9],
            [9,4,3,6,8,2,1,7,5],
            [6,7,5,4,9,1,2,8,3],
            [1,5,4,2,3,7,8,9,6],
            [3,6,9,8,4,5,7,2,1],
            [2,8,7,1,6,9,5,3,4],
            [5,2,1,9,7,4,3,6,8],
            [4,3,8,5,2,6,9,1,7],
            [7,9,6,3,1,8,4,5,2]
        ])
    }
    
    func testStateMachineDetectsSloMoveEasyPuzzle() {
        runTest(videoFilename: "SloMoveEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func testStateMachineDetectsMedMoveEasyPuzzle() {
        runTest(videoFilename: "MedMoveEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func testStateMachineDetectsFastMoveEasyPuzzle() {
        runTest(videoFilename: "FastMoveEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func testStateMachineDetectsRotateEasyPuzzle() {
        runTest(videoFilename: "RotateEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func testStateMachineDetectsZoomEasyPuzzle() {
        runTest(videoFilename: "ZoomEasyPuzzle", expectedSolvedPuzzle: [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
         ])
    }
    
    func runTest(videoFilename: String, expectedSolvedPuzzle: [[Int]]) {
        let fileString = Bundle(for: type(of: self)).path(forResource: videoFilename, ofType: "MOV")!
        let videoURL = URL(fileURLWithPath: fileString)
        let videoFile = AVAsset(url: videoURL)
        let videoReader = VideoReader(videoAsset: videoFile)!
        var framesIn = 0
        var testEvents = [TestEvent]()
        let expectation = expectation(description: "digits recognized")
        testQueue.async {
            while let nextFrame = videoReader.nextFrame(){
                framesIn += 1
                print("frame# \(framesIn)")
                let image = CIImage(cvPixelBuffer: nextFrame)
                self.stateMachineUnderTest.stateMachineQueue.sync {
                    self.stateMachineUnderTest.eventHandler(event: .imageIn(image, orientation: videoReader.orientation))
                    guard let currentPuzzle = self.stateMachineUnderTest.currentDetectedPuzzles.first else {
                        testEvents.append(TestEvent(frameNumber: framesIn, currentDetectedPuzzle: nil))
                        return
                    }
                    print("Puzzle coordinates: \(currentPuzzle.value.rect)")
                    testEvents.append(TestEvent(frameNumber: framesIn, currentDetectedPuzzle: currentPuzzle.value))
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 50.0) {_ in
            let eventsWithExpectedSolvedPuzzle = testEvents.filter { $0.hasExpectedSolution(expectedSolvedPuzzle) }
            let eventsWithFailedPuzzle = testEvents.filter { !$0.hasExpectedSolution(expectedSolvedPuzzle) }
            let eventsWithNoRectangle = testEvents.filter { $0.currentDetectedPuzzle == nil }
            let eventsWithNoDigitsDetected = testEvents.filter {
                $0.currentDetectedPuzzle != nil &&
                $0.currentDetectedPuzzle!.unSolvedPuzzle == nil
            }
            let puzzlesDetectedTotal = eventsWithExpectedSolvedPuzzle.count
            let expectedSolvedPuzzleHist = eventsWithExpectedSolvedPuzzle.reduce([Int:Int]()) { histogram, event in
                let eventBucket = Int(Double(event.frameNumber) / Double(framesIn) * 10.0)
                let currentBucketValue = histogram[eventBucket] ?? 0
                var histogramCopy = histogram
                histogramCopy[eventBucket] = currentBucketValue + 1
                return histogramCopy
            }
            let failedPuzzleHist = eventsWithFailedPuzzle.reduce([Int:Int]()) { histogram, event in
                let eventBucket = Int(Double(event.frameNumber) / Double(framesIn) * 10.0)
                let currentBucketValue = histogram[eventBucket] ?? 0
                var histogramCopy = histogram
                histogramCopy[eventBucket] = currentBucketValue + 1
                return histogramCopy
            }
            let failedRectangleHist = eventsWithNoRectangle.reduce([Int:Int]()) { histogram, event in
                let eventBucket = Int(Double(event.frameNumber) / Double(framesIn) * 10.0)
                let currentBucketValue = histogram[eventBucket] ?? 0
                var histogramCopy = histogram
                histogramCopy[eventBucket] = currentBucketValue + 1
                return histogramCopy
            }
            let noDigitsHist = eventsWithNoDigitsDetected.reduce([Int:Int]()) { histogram, event in
                let eventBucket = Int(Double(event.frameNumber) / Double(framesIn) * 10.0)
                let currentBucketValue = histogram[eventBucket] ?? 0
                var histogramCopy = histogram
                histogramCopy[eventBucket] = currentBucketValue + 1
                return histogramCopy
            }
            let fractionDetected = Double(puzzlesDetectedTotal)/Double(framesIn)
            print("frames in = \(framesIn)")
            print("puzzles detected = \(puzzlesDetectedTotal)")
            print("fraction detected = \(fractionDetected)")
            print("Histogram of puzzles detected over clip duration: \(expectedSolvedPuzzleHist.sorted(by: <))")
            print("Histogram of failed puzzle detection over clip duration: \(failedPuzzleHist.sorted(by: <))")
            print("Histogram of failed rectangle detection over clip duration: \(failedRectangleHist.sorted(by: <))")
            print("Histogram of frames with no digits over clip duration: \(noDigitsHist.sorted(by: <))")

            XCTAssertGreaterThan(fractionDetected, 0.5)
        }
    }
    
    struct TestEvent {
        let frameNumber: Int
        let currentDetectedPuzzle: MainViewModel.DetectedPuzzle?
        func hasExpectedSolution(_ expectedSolvedPuzzle: [[Int]]) -> Bool {
            guard let puzzleEntry = currentDetectedPuzzle?.solvedPuzzle else {
                return false
            }
            return puzzleEntry == expectedSolvedPuzzle
        }
    }
}
