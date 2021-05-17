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

struct Puzzle {
    var puzzle = [[Int]]()
    var emptyCells = [CellCoordinate:[Int]]()
    init(puzzle: [[Int]]) {
        self.puzzle = puzzle
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
        for colIndex in 0...8 {
            if let index = candidates.firstIndex(of: puzzle[cell.row][colIndex]){
                candidates.remove(at: index)
            }
        }
        for rowIndex in 0...8 {
            if let index = candidates.firstIndex(of: puzzle[rowIndex][cell.col]){
                candidates.remove(at: index)
            }
        }
        let boxOriginRow = (cell.row / 3) * 3
        let boxOriginCol = (cell.col / 3) * 3
        for boxRowIndex in boxOriginRow...boxOriginRow + 2 {
            for boxColIndex in boxOriginCol...boxOriginCol + 2 {
                if let index = candidates.firstIndex(of: puzzle[boxRowIndex][boxColIndex]){
                    candidates.remove(at: index)
                }
            }
        }
        return candidates
    }

    public func expandedStates() -> [Puzzle] {
        var expandedStates = [Puzzle]()
        let blankCell = self.findBlankCell()
        guard let cell = blankCell else {
            return expandedStates
        }
        let candidatesForCell = self.candidatesForCell(cell: cell)
        for candidate in candidatesForCell {
            var puzzleToFillOut = self.puzzle
            puzzleToFillOut[cell.row][cell.col] = candidate
            expandedStates.append(Puzzle(puzzle: puzzleToFillOut))
        }
        return expandedStates
    }
}

final class PuzzleSolver {
    static var solvedPuzzleCache = [[[Int]]: Puzzle]()
    static public func solvePuzzle(puzzle: Puzzle) -> Puzzle {
        if let cachedPuzzle = solvedPuzzleCache[puzzle.puzzle] {
            return cachedPuzzle
        }
        var puzzleContainer = [puzzle]
        while puzzleContainer.count > 0 {
            let puzzleToEvaluate = puzzleContainer.removeLast()
            if puzzleToEvaluate.isSolved() {
                solvedPuzzleCache[puzzle.puzzle] = puzzleToEvaluate
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
