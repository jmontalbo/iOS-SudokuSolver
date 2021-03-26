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

//    func testDetectorDetectsSingleDigit0() throws {
//        let fileString = Bundle(for: type(of: self)).path(forResource: "singleDigit0", ofType: "png")!
//        let imageWithSingleDigit = CIImage(image: UIImage(contentsOfFile: fileString)!)!
//        let detectedDigits = detectorUnderTest.detect(imageWithSingleDigit)
//        XCTAssertEqual(detectedDigits.count, 1)
//        if let detectedDigit = detectedDigits.first {
//            let imageCenter = CGPoint(x: imageWithSingleDigit.extent.width / 2.0,
//                                      y: imageWithSingleDigit.extent.height / 2.0)
//            XCTAssertTrue(detectedDigit.boundingBox.contains(imageCenter))
//            XCTAssertEqual(detectedDigit.digit, "0")
//        }
//    }
//
//    func testDetectorDetectsSingleDigit2() throws {
//        let fileString = Bundle(for: type(of: self)).path(forResource: "singleDigit2", ofType: "png")!
//        let imageWithSingleDigit = CIImage(image: UIImage(contentsOfFile: fileString)!)!
//        let detectedDigits = detectorUnderTest.detect(imageWithSingleDigit)
//        XCTAssertEqual(detectedDigits.count, 1)
//        if let detectedDigit = detectedDigits.first {
//            let imageCenter = CGPoint(x: imageWithSingleDigit.extent.width / 2.0,
//                                      y: imageWithSingleDigit.extent.height / 2.0)
//            XCTAssertTrue(detectedDigit.boundingBox.contains(imageCenter))
//            XCTAssertEqual(detectedDigit.digit, "2")
//        }
//    }

    func testDetectorDetectsDigitsPuzzle4() throws {
        let fileString = Bundle(for: type(of: self)).path(forResource: "Puzzle4", ofType: "png")!
        let imageWithPuzzle = CIImage(image: UIImage(contentsOfFile: fileString)!)!
        let detectedDigits = detectorUnderTest.detect(imageWithPuzzle)
        XCTAssertEqual(detectedDigits.count, 17)
    }
}

