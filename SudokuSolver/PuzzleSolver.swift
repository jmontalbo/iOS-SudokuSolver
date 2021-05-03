//
//  PuzzleSolver.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 4/11/21.
//

import Foundation
import UIKit


//# Puzzle Format and Definitions:
//# Python matrices are lists of lists, so a puzzle is 9 lists of 9 digits
//# Cells with a zero are considered blanks and need to be replace with digits
//# to complete the puzzle
//#
//#     BoxX    0  |  1  |  2
//# Cols(x)   0 1 2|3 4 5|6 7 8   BoxY
//# Row(y) 0 [5,3,0|0,7,0|0,0,0]
//#        1 [6,0,0|1,9,5|0,0,0]   0
//#        2 [0,9,8|0,0,0|0,6,0]
//#          ------|-----|------------
//#        3 [8,0,0|0,6,0|0,0,3]
//#        4 [4,0,0|8,0,3|0,0,1]   1
//#        5 [7,0,0|0,2,0|0,0,6]
//#          ------|-----|------------
//#        6 [0,6,0|0,0,0|2,8,0]
//#        7 [0,0,0|4,1,9|0,0,5]   2
//#        8 [0,0,0|0,8,0|0,7,9]
//#
//#

struct Puzzle: Equatable {
    private var row0 = 0
    private var row1 = 0
    private var row2 = 0
    private var row3 = 0
    private var row4 = 0
    private var row5 = 0
    private var row6 = 0
    private var row7 = 0
    private var row8 = 0
    init(puzzle: [[Int]]) {
        assert(puzzle.count == 9)
        assert(puzzle[0].count == 9)
        for row in 0...8 {
            for col in 0...8 {
                self[row, col] = puzzle[row][col]
            }
        }

    }
    
    subscript(row: Int, column: Int) -> Int {
        get {
            assert(row < 9 && row >= 0 && column < 9 && column >= 0, "Index out of range")
            switch row {
            case 0:
                return row0 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 1:
                return row1 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 2:
                return row2 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 3:
                return row3 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 4:
                return row4 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 5:
                return row5 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 6:
                return row6 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 7:
                return row7 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            case 8:
                return row8 / (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue % 10
            default:
                assertionFailure()
                return 0
            }
        }
        
        set {
            assert(row < 9 && row >= 0 && column < 9 && column >= 0, "Index out of range")
            assert(newValue < 10 && newValue >= 0, "Value out of range")
            switch row {
            case 0:
                row0 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 1:
                row1 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 2:
                row2 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 3:
                row3 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 4:
                row4 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 5:
                row5 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 6:
                row6 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 7:
                row7 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            case 8:
                row8 += (pow(10, (9 - column - 1)) as NSDecimalNumber).intValue * newValue
            default:
                assertionFailure()
            }
        }
    }
    
    private func emptyCells() -> [CellCoordinate:[Int]] {
        var result = [CellCoordinate:[Int]]()
        for row in 0...8 {
            for col in 0...8 {
                if self[row, col] == 0 {
                    let cellCoordinate = CellCoordinate(row: row, col: col)
                    result[cellCoordinate] = self.candidatesForCell(cell: cellCoordinate)
                }
            }
        }
        return result
    }

    
    public func isSolved() -> Bool {
        for row in 0...8 {
            for col in 0...8 {
                if self[row, col] == 0 {
                    return false
                }
            }
        }
        return true
    }

    private func findBlankCell() -> CellCoordinate? {
        var cellToFillIn: CellCoordinate? = nil
        var minimumCandidateCount = Int.max
        for (cell, candidates) in emptyCells() {
            if candidates.count < minimumCandidateCount {
                cellToFillIn = cell
                minimumCandidateCount = candidates.count
            }
        }
        return cellToFillIn
    }

    public func candidatesForCell(cell: CellCoordinate) -> [Int] {
        var candidates = [1,2,3,4,5,6,7,8,9]
        for colIndex in 0...8 {
            if let index = candidates.firstIndex(of: self[cell.row, colIndex]){
                candidates.remove(at: index)
            }
        }
        for rowIndex in 0...8 {
            if let index = candidates.firstIndex(of: self[rowIndex, cell.col]){
                candidates.remove(at: index)
            }
        }
        let boxOriginRow = (cell.row / 3) * 3
        let boxOriginCol = (cell.col / 3) * 3
        for boxRowIndex in boxOriginRow...boxOriginRow + 2 {
            for boxColIndex in boxOriginCol...boxOriginCol + 2 {
                if let index = candidates.firstIndex(of: self[boxRowIndex, boxColIndex]){
                    candidates.remove(at: index)
                }
            }
        }
        return candidates
    }

    public func expandedStates() -> [Puzzle] {
        var expandedStates = [Puzzle]()
        let blankCell = findBlankCell()
        guard let cell = blankCell else {
            return expandedStates
        }
        let candidates = candidatesForCell(cell: cell)
        for candidate in candidates {
            var puzzleToFillOut = self
            puzzleToFillOut[cell.row, cell.col] = candidate
            expandedStates.append(puzzleToFillOut)
        }
        return expandedStates
    }


//    def __str__(self):
//        puzzleString = ""
//        blankCell = self.__findBlankCell()
//        puzzleCopy = copy.deepcopy(self.puzzle)
//        if blankCell is not None:
//            puzzleCopy[blankCell[0]][blankCell[1]] = Fore.GREEN + "X" + Style.RESET_ALL
//        for lines in puzzleCopy:
//            lineStr = [str(line) for line in lines]
//            puzzleString += " ".join(lineStr) + "\n"
//        if blankCell is not None:
//            candidatesStr = "X ?= " + str(self.__candidatesForCell(blankCell)) + "\n"
//            puzzleString += candidatesStr
//        return puzzleString
//
//
    
}

final class PuzzleSolver {
    static public func solvePuzzle(puzzle: Puzzle) -> Puzzle {
        var puzzleContainer = [puzzle]
        while puzzleContainer.count > 0 {
            let puzzleToEvaluate = puzzleContainer.removeLast()
            if puzzleToEvaluate.isSolved(){
                return puzzleToEvaluate
            }
            puzzleContainer.append(contentsOf: puzzleToEvaluate.expandedStates())
        }
        return puzzle
    }
}

struct CellCoordinate: Hashable {
    var row: Int
    var col: Int
}
