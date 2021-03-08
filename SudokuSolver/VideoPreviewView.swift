/* Copyright © 2019 Apple Inc.
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import AVFoundation
import Vision

class VideoPreviewView: UIView {
    
    private var boxLayer = [CAShapeLayer]()
    private var visionToAVFTransform = CGAffineTransform.identity
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
    
    func show(rectangles: [VNRectangleObservation]) {
        DispatchQueue.main.async {
            self.removeBoxes()
            for rectangle in rectangles {
                self.draw(rect: rectangle)
            }
        }
    }
    private func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    private func draw(rect: VNRectangleObservation) {
        let layer = CAShapeLayer()
        layer.opacity = 0.25
        layer.strokeColor = UIColor.green.cgColor
        layer.lineWidth = 2
        let linePath = UIBezierPath()
        let transform = CGAffineTransform.identity
            .scaledBy(x: -1, y: 1)
            .scaledBy(x: videoPreviewLayer.bounds.size.width, y: videoPreviewLayer.bounds.size.height)
            .rotated(by: .pi/2.0)
        linePath.move(to: rect.topLeft.applying(transform))
        linePath.addLine(to: rect.topRight.applying(transform))
        linePath.addLine(to: rect.bottomRight.applying(transform))
        linePath.addLine(to: rect.bottomLeft.applying(transform))
        linePath.addLine(to: rect.topLeft.applying(transform))
        linePath.close()
        layer.path = linePath.cgPath
        boxLayer.append(layer)
        videoPreviewLayer.insertSublayer(layer, at: 1)
    }
}
