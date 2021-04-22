//
//  DigitDetectorTests.swift
//  SudokuSolverTests
//
//  Created by Joe Montalbo on 3/21/21.
//

import Foundation
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
            for detectedResult in detectedResults! {
                let validSquares = puzzle1ExpectedResults[detectedResult.digit]!
                let detectedResultCoordinates = (detectedResult.row, detectedResult.column)
                XCTAssertTrue(validSquares.contains(where: {
                    (validSquare) -> Bool in
                    return detectedResultCoordinates.0 == validSquare.0 && detectedResultCoordinates.1 == validSquare.1
                } ))
            }
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
            var detectedResultsDict = [Int:[(Int, Int)]]()
            for detectedResult in detectedResults! {
                var coordinates = detectedResultsDict[detectedResult.digit] ?? [(Int, Int)]()
                coordinates.append((detectedResult.row, detectedResult.column))
                detectedResultsDict[detectedResult.digit] = coordinates
                let validSquares = puzzle1ExpectedResults[detectedResult.digit]!
                let detectedResultCoordinates = (detectedResult.row, detectedResult.column)
                XCTAssertTrue(validSquares.contains(where: {
                    (validSquare) -> Bool in
                    return detectedResultCoordinates.0 == validSquare.0 && detectedResultCoordinates.1 == validSquare.1
                } ))
            }
            print(detectedResultsDict)
        }
    }
    
//    func testDetectorDetectsDigitsPuzzle4() throws {
//        let puzzle1ExpectedResults = [
//            "1": [(0, 0), (4, 1), (6, 7)],
//            "2": [(1, 4), (4, 8)],
//            "3": [(1, 1), (3, 3), (6, 0), (8, 6)],
//            "4": [(5, 5), (7, 1)],
//            "5": [(2, 6), (3, 2)],
//            "6": [(2, 3), (5, 0)],
//            "7": [(0, 5), (7, 8), (8, 2)],
//            "8": [(1, 8), (4, 4)],
//            "9": [(0, 7), (2, 2), (3, 6)],
//        ]
//        let testExpectation = expectation(description: "Received Detected Results")
//        let fileString = Bundle(for: type(of: self)).path(forResource: "Puzzle4", ofType: "png")!
//        let imageWithPuzzle = CIImage(image: UIImage(contentsOfFile: fileString)!)!
//        var detectedResults: [DigitDetectorResult]? = nil
//        detectorUnderTest.detect(imageWithPuzzle) { results in
//            detectedResults = results
//            testExpectation.fulfill()
//        }
//        waitForExpectations(timeout: 5.0) {_ in
//            XCTAssertEqual(detectedResults!.count, 23)
////            for detectedResult in detectedResults! {
////                let validSquares = puzzle1ExpectedResults[detectedResult.digit]!
////                let detectedResultCoordinates = (detectedResult.row, detectedResult.column)
////                XCTAssertTrue(validSquares.contains(where: {
////                    (validSquare) -> Bool in
////                    return detectedResultCoordinates.0 == validSquare.0 && detectedResultCoordinates.1 == validSquare.1
////                } ))
////            }
//        }
//    }
}
