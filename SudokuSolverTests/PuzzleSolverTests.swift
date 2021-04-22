//
//  PuzzleSolverTests.swift
//  SudokuSolverTests
//
//  Created by Joe Montalbo on 4/15/21.
//

import Foundation
import XCTest
@testable import SudokuSolver

class PuzzleSolverTests: XCTestCase {
    
    override func setUpWithError() throws {
        //        detectorUnderTest = DigitDetector()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_isSolved_puzzleMarkedSolved(){
        let solvedPuzzle = [
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
        let testPuzzle = PuzzleSolver(puzzle: solvedPuzzle)
        XCTAssertTrue(testPuzzle.isSolved())
    }
    
    func test_isNotSolved_puzzleMarkedNotSolved(){
        let unSolvedPuzzle = [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,0,0,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,0,0,0,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
        ]
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        XCTAssertFalse(testPuzzle.isSolved())
    }
    
    func test_expandedStates_returnsSomeStatesForUnsolvedPuzzle(){
        let unSolvedPuzzle = [
            [5,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]
        ]
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        let expandedStates = testPuzzle.expandedStates()
        XCTAssertGreaterThan(expandedStates.count, 0)
    }
    
    func testCellCandidatesReturnsSomeCandidatesForCell(){
        let unSolvedPuzzle = [
            [5,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]
        ]
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        let candidates = testPuzzle.candidatesForCell(cell: CellCoordinate(row: 0, col: 2))
        XCTAssertEqual(candidates, [1, 2, 4])
    }
    
    func test_expandedStates_returnsNoStateForSolvedPuzzle() {
        let solvedPuzzle = [
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
        let testPuzzle = PuzzleSolver(puzzle: solvedPuzzle)
        let expandedStates = testPuzzle.expandedStates()
        XCTAssertEqual(expandedStates.count, 0)
    }
    
    func test_unSolvedPuzzleCanBeSolved(){
        let unSolvedPuzzle = [
            [5,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]
        ]
        
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
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        let actualSolvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: testPuzzle)
        XCTAssertEqual(actualSolvedPuzzle.puzzle, expectedSolvedPuzzle)
    }
    
    func test_HardUnSolvedPuzzleCanBeSolved(){
        let unSolvedPuzzle = [
            [0,0,7,3,0,0,2,0,5],
            [0,0,4,0,0,9,0,0,0],
            [0,0,0,0,0,0,7,6,0],
            [4,0,0,0,0,0,0,7,8],
            [0,1,0,5,0,0,0,0,2],
            [0,0,8,0,0,6,1,0,0],
            [0,2,0,0,0,1,4,0,0],
            [0,0,0,8,0,0,0,3,7],
            [0,0,0,0,0,5,0,0,0]
        ]
        
        let expectedSolvedPuzzle = [
            [1,8,7,3,6,4,2,9,5],
            [2,6,4,7,5,9,8,1,3],
            [5,3,9,2,1,8,7,6,4],
            [4,5,2,1,9,3,6,7,8],
            [9,1,6,5,8,7,3,4,2],
            [3,7,8,4,2,6,1,5,9],
            [7,2,5,9,3,1,4,8,6],
            [6,9,1,8,4,2,5,3,7],
            [8,4,3,6,7,5,9,2,1]
        ]
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        let actualSolvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: testPuzzle)
        XCTAssertEqual(actualSolvedPuzzle.puzzle, expectedSolvedPuzzle)
    }
    
    func test_HardestUnSolvedPuzzleCanBeSolved() {
        let unSolvedPuzzle = [
            [8,0,0,0,0,0,0,0,0],
            [0,0,3,6,0,0,0,0,0],
            [0,7,0,0,9,0,2,0,0],
            [0,5,0,0,0,7,0,0,0],
            [0,0,0,0,4,5,7,0,0],
            [0,0,0,1,0,0,0,3,0],
            [0,0,1,0,0,0,0,6,8],
            [0,0,8,5,0,0,0,1,0],
            [0,9,0,0,0,0,4,0,0]
        ]
        
        let expectedSolvedPuzzle = [
            [8,1,2,7,5,3,6,4,9],
            [9,4,3,6,8,2,1,7,5],
            [6,7,5,4,9,1,2,8,3],
            [1,5,4,2,3,7,8,9,6],
            [3,6,9,8,4,5,7,2,1],
            [2,8,7,1,6,9,5,3,4],
            [5,2,1,9,7,4,3,6,8],
            [4,3,8,5,2,6,9,1,7],
            [7,9,6,3,1,8,4,5,2]
        ]
        
        let testPuzzle = PuzzleSolver(puzzle: unSolvedPuzzle)
        let actualSolvedPuzzle = PuzzleSolver.solvePuzzle(puzzle: testPuzzle)
        XCTAssertEqual(actualSolvedPuzzle.puzzle, expectedSolvedPuzzle)
    }
}
