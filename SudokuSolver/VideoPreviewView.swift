/* Copyright © 2019 Apple Inc.
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import AVFoundation
import Vision

class VideoPreviewView: UIView {
    
    private var boxLayer = [CALayer]()
    private var visionToAVFTransform = CGAffineTransform.identity
    private var puzzleDigitLabels = [UILabel]()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func show(puzzles: [UUID : DetectedPuzzle]) {
        DispatchQueue.main.async {
            self.removeBoxes()
            for (_, puzzle) in puzzles {
                self.draw(puzzle: puzzle)
            }
        }
    }
    private func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
        for label in puzzleDigitLabels {
            label.removeFromSuperview()
        }
        puzzleDigitLabels.removeAll()
    }
    private func draw(puzzle: DetectedPuzzle) {
        let rect = puzzle.rect
        let layer = CAShapeLayer()
        layer.opacity = 0.25
        layer.strokeColor = UIColor.green.cgColor
        layer.lineWidth = 2
        let linePath = UIBezierPath()
        let transform = CGAffineTransform.identity
            .scaledBy(x: 1, y: -1)
            .scaledBy(x: videoPreviewLayer.bounds.size.width, y: videoPreviewLayer.bounds.size.height)
            .translatedBy(x: 0, y: -1)
        let unNormalizedTopLeft = rect.topLeft.applying(transform)
        let unNormalizedTopRight = rect.topRight.applying(transform)
        let unNormalizedBottomLeft = rect.bottomLeft.applying(transform)
        let unNormalizedBottomRight = rect.bottomRight.applying(transform)
        linePath.move(to: unNormalizedTopLeft)
        linePath.addLine(to: unNormalizedTopRight)
        linePath.addLine(to: unNormalizedBottomRight)
        linePath.addLine(to: unNormalizedBottomLeft)
        linePath.addLine(to: unNormalizedTopLeft)
        linePath.close()
        layer.path = linePath.cgPath
        boxLayer.append(layer)
        videoPreviewLayer.insertSublayer(layer, at: 1)
        guard let solvedPuzzle = puzzle.solvedPuzzle, let unSolvedPuzzle = puzzle.unSolvedPuzzle else {
            return
        }
        let cellWidth = (unNormalizedTopRight.x - unNormalizedTopLeft.x) / 9.0
        let cellHeight = (unNormalizedBottomRight.y - unNormalizedTopRight.y) / 9.0
        for row in 0...8 {
            for col in 0...8 {
                if solvedPuzzle[row][col] != unSolvedPuzzle[row][col] {
                    let cellOriginX = unNormalizedTopLeft.x + (cellWidth * CGFloat(col))
                    let cellOriginY = unNormalizedTopLeft.y + (cellWidth * CGFloat(row))
                    let label = UILabel(frame: CGRect(x: cellOriginX, y: cellOriginY, width: cellWidth, height: cellHeight))
                    label.text = String(solvedPuzzle[row][col])
                    label.textColor = UIColor.white
                    label.font = UIFont.boldSystemFont(ofSize: 15)
                    label.textAlignment = .center
                    addSubview(label)
                    bringSubviewToFront(label)
                    puzzleDigitLabels.append(label)
                }
            }
        }
    }
}
