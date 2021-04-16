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

class PuzzleSolver {
    var puzzle = [[Int]]()
    var rows = [[Int]]()
    var cols = [[Int]]()
    var boxs = [[Int]]()
    var emptyCells = [CellCoordinate:[Int]]()
    init(puzzle: [[Int]]) {
        self.puzzle = puzzle
        self.rows = self.puzzle
        for i in 0...8 {
            var result = [Int]()
            for c in 0...8 {
                result.append(self.puzzle[c][i])
            }
            self.cols.append(result)
        }
        
        for j in 0...2 {
            for k in 0...2 {
                var result = [Int]()
                for y in 0...2 {
                    for x in 0...2 {
                        result.append(self.puzzle[y+j*3][x+k*3])
                    }
                }
                self.boxs.append(result)
            }
        }
        
        for r in 0...8 {
            for c in 0...8 {
                if self.puzzle[r][c] == 0 {
                    let cellCoordinate = CellCoordinate(row: r, col: c)
                    self.emptyCells[cellCoordinate] = self.candidatesForCell(cell: cellCoordinate)
                }
            }
        }
    }

    public func isSolved() -> Bool {
        return self.emptyCells.count == 0
    }


    private func findBlankCell() -> CellCoordinate? {
        var cellToFillIn: CellCoordinate? = nil
        var minimumCandidateCount = Int.max
        for (cell, candidates) in self.emptyCells {
            if candidates.count < minimumCandidateCount {
                cellToFillIn = cell
                minimumCandidateCount = candidates.count
            }
        }
        return cellToFillIn
    }

    public func candidatesForCell(cell: CellCoordinate) -> [Int] {
        var candidates = [1,2,3,4,5,6,7,8,9]
        let candidateRows = self.rows[cell.row]
        let candidateCols = self.cols[cell.col]
        let candidateBoxs = self.boxs[Int(cell.col/3) + 3 * Int(cell.row/3)]
        for j in 1...9 {
            if candidateRows.contains(j) && candidates.contains(j) { candidates = candidates.filter(){$0 != j} }
            if candidateCols.contains(j) && candidates.contains(j) { candidates = candidates.filter(){$0 != j} }
            if candidateBoxs.contains(j) && candidates.contains(j) { candidates = candidates.filter(){$0 != j} }
        }
        return candidates
    }


    public func expandedStates() -> [PuzzleSolver] {
        var expandedStates = [PuzzleSolver]()
        let blankCell = self.findBlankCell()
        guard let cell = blankCell else {
            return expandedStates
        }
        let candidatesForCell = self.candidatesForCell(cell: cell)
        for candidate in candidatesForCell {
            var puzzleToFillOut = self.puzzle
            puzzleToFillOut[cell.row][cell.col] = candidate
            expandedStates.append(PuzzleSolver(puzzle: puzzleToFillOut))
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
    
    static public func solvePuzzle(puzzle: PuzzleSolver) -> PuzzleSolver {
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
//    static func == (lhs: CellCoordinate, rhs: CellCoordinate) -> Bool {
//        return lhs.row == rhs.row && lhs.col == rhs.col
//    }
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(row)
//        hasher.combine(col)
//    }
}
