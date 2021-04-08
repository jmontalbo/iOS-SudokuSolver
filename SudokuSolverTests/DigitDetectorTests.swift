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
            "1": [(1, 0), (5, 7), (6, 5)],
            "2": [(2, 6), (7, 2)],
            "3": [(2, 4), (8, 6)],
            "4": [(2, 3), (5, 6), (8, 1)],
            "5": [(4, 3), (7, 7)],
            "6": [(3, 8)],
            "7": [(0, 3)],
            "8": [(5, 8), (6, 4)],
            "9": [(4, 5)],
        ]
        let testExpectation = expectation(description: "Received Detected Results")
        let fileString = Bundle(for: type(of: self)).path(forResource: "puzzle1", ofType: "png")!
        let imageWithPuzzle = CIImage(image: UIImage(contentsOfFile: fileString)!)!
        var detectedResults: [DigitDetectorResult]? = nil
        detectorUnderTest.detect(imageWithPuzzle) { results in
            detectedResults = results
            testExpectation.fulfill()
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
}
