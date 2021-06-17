//
//  PuzzleDetector.swift
//  SudokuSolver
//
//  Created by Joe Montalbo on 4/18/21.
//

import Foundation

class PuzzleDetector {
    
    private var detectedPuzzles = [[[Int]]]()
    private var lastPuzzleReturned = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
    
    func detect(digits: [DigitDetectorResult]) -> [[Int]]? {
        guard digits.count > 16 else {
//            detectedPuzzles.removeAll()
            return nil
        }
        var puzzle = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
        for entry in digits {
            guard entry.row < 9, entry.column < 9 else {
//                detectedPuzzles.removeAll()
                return nil
            }
            puzzle[entry.row][entry.column] = entry.digit
        }
//        return puzzle
        detectedPuzzles.append(puzzle)
        if detectedPuzzles.count > 3 {
            detectedPuzzles.remove(at: 0)
        }
        var puzzleVotes = [[[Int]]:Int]()
        for puzzle in detectedPuzzles {
            guard let currentPuzzleVotes = puzzleVotes[puzzle] else {
                puzzleVotes[puzzle] = 0
                continue
            }
            puzzleVotes[puzzle] = currentPuzzleVotes + 1
            if currentPuzzleVotes + 1 > 1 {
//                print("puzzleVotes \(puzzleVotes)")
                return puzzle
            }
        }
        return nil
    }
}

