//
//  DigitDetectorTests.swift
//  SudokuSolverTests
//
//  Created by Joe Montalbo on 3/21/21.
//

import Foundation
import AVFoundation
import XCTest
@testable import SudokuSolver

class DigitDetectorTests: XCTestCase {
    
    var detectorUnderTest: DigitDetector!
    
    override func setUpWithError() throws {
        detectorUnderTest = DigitDetector()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDetectorDetectsDigitsPuzzle1() throws {
        let puzzle1ExpectedResults = [
            1: [(1, 0), (5, 7), (6, 5)],
            2: [(2, 6), (7, 2)],
            3: [(2, 4), (8, 6)],
            4: [(2, 3), (5, 6), (8, 1)],
            5: [(4, 3), (7, 7)],
            6: [(3, 8)],
            7: [(0, 3)],
            8: [(5, 8), (6, 4)],
            9: [(4, 5)],
        ]
        let testExpectation = expectation(description: "Received Detected Results")
        let fileString = Bundle(for: type(of: self)).path(forResource: "puzzle1", ofType: "png")!
        let imageWithPuzzle = CIImage(image: UIImage(contentsOfFile: fileString)!)!
        var detectedResults: [DigitDetectorResult]? = nil
        detectorUnderTest.detect(imageWithPuzzle) {_ in
            self.detectorUnderTest.detect(imageWithPuzzle) {_ in
                self.detectorUnderTest.detect(imageWithPuzzle) { results in
                    detectedResults = results
                    testExpectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5.0) {_ in
            XCTAssertEqual(detectedResults!.count, 17)
            XCTAssertTrue(DigitDetectorTests.digitResultsAreEqual(digitResults: detectedResults!, expectedResults: puzzle1ExpectedResults))
        }
    }
    
    func testDetectorDetectsDigitsPuzzleImage() throws {
        let puzzle1ExpectedResults = [
            1: [(1, 3), (4, 8), (7, 4)],
            2: [(5, 4), (6, 6)],
            3: [(0, 1), (3, 8), (4, 5)],
            4: [(4, 0), (7, 3)],
            5: [(0, 0), (1, 5), (7, 8)],
            6: [(1, 0), (2, 7), (3, 4), (5, 8), (6, 1)],
            7: [(0, 4), (5, 0), (8, 7)],
            8: [(2, 2), (3, 0), (4, 3), (6, 7), (8, 4)],
            9: [(1, 4), (2, 1), (7, 5), (8, 8)],
        ]
        let testExpectation = expectation(description: "Received Detected Results")
        let fileString = Bundle(for: type(of: self)).path(forResource: "puzzleImage", ofType: "png")!
        let imageWithPuzzle = CIImage(image: UIImage(contentsOfFile: fileString)!)!
        var detectedResults: [DigitDetectorResult]? = nil
        detectorUnderTest.detect(imageWithPuzzle) {_ in
            self.detectorUnderTest.detect(imageWithPuzzle) {_ in
                self.detectorUnderTest.detect(imageWithPuzzle) { results in
                    detectedResults = results
                    testExpectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5.0) {_ in
            XCTAssertEqual(detectedResults!.count, 30)
            XCTAssertTrue(DigitDetectorTests.digitResultsAreEqual(digitResults: detectedResults!, expectedResults: puzzle1ExpectedResults))
        }
    }
    
    
    func testDetectorCanDetectDigits() throws {
        let puzzle1ExpectedResults = [
            1: [(1, 3), (4, 8), (7, 4)],
            2: [(5, 4), (6, 6)],
            3: [(0, 1), (3, 8), (4, 5)],
            4: [(4, 0), (7, 3)],
            5: [(0, 0), (1, 5), (7, 8)],
            6: [(1, 0), (2, 7), (3, 4), (5, 8), (6, 1)],
            7: [(0, 4), (5, 0), (8, 7)],
            8: [(2, 2), (3, 0), (4, 3), (6, 7), (8, 4)],
            9: [(1, 4), (2, 1), (7, 5), (8, 8)],
        ]
        let fileString = Bundle(for: type(of: self)).path(forResource: "IMG_2745", ofType: "MOV")!
        let videoURL = URL(fileURLWithPath: fileString)
        let videoFile = AVAsset(url: videoURL)
        let videoReader = VideoReader(videoAsset: videoFile)!
        let detectorUnderTest = DigitDetector()
        var framesIn = 0.0
        var digitsDetected = 0.0
        while let nextFrame = videoReader.nextFrame(){
            framesIn += 1.0
            let image = CIImage(cvPixelBuffer: nextFrame)
            let testExpectation = expectation(description: "Received Detected Results")
            detectorUnderTest.detect(image) { results in
                testExpectation.fulfill()
                print("results \(results)")
                if DigitDetectorTests.digitResultsAreEqual(digitResults: results, expectedResults: puzzle1ExpectedResults){
                    digitsDetected += 1.0
                }
            }
        }
        waitForExpectations(timeout: 10.0) {_ in
            let fractionDetected = digitsDetected/framesIn
            print("frames in = \(framesIn)")
            print("fraction detected = \(fractionDetected)")
            XCTAssertGreaterThan(fractionDetected, 0.5)
        }
    }
    
    private static func digitResultsAreEqual(digitResults: [DigitDetectorResult], expectedResults: [Int: [(Int,Int)]]) -> Bool {
        let expectedResultCount = expectedResults.values.flatMap { Array($0) }.count
//        print("expectedValuesCount \(expectedResultCount)")
        guard expectedResultCount == digitResults.count else {
            return false
        }
        var detectedResultsDict = [Int:[(Int, Int)]]()
        for detectedResult in digitResults {
            var coordinates = detectedResultsDict[detectedResult.digit] ?? [(Int, Int)]()
            coordinates.append((detectedResult.row, detectedResult.column))
            detectedResultsDict[detectedResult.digit] = coordinates
            guard let validSquares = expectedResults[detectedResult.digit] else {
                return false
            }
            let detectedResultCoordinates = (detectedResult.row, detectedResult.column)
            let detectedResultInValidSquares = validSquares.contains(where: {
                (validSquare) -> Bool in
                return detectedResultCoordinates.0 == validSquare.0 && detectedResultCoordinates.1 == validSquare.1
            } )
            if !detectedResultInValidSquares {
                return false
            }
        }
        return true
    }
}
