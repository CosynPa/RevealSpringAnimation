//
//  ShapeView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/8.
//

import Foundation
import UIKit

enum ShapeType {
    case square
    case arrow
}

class ShapeView: UIView {
    var color = UIColor.black {
        didSet { setNeedsDisplay() }
    }

    var type = ShapeType.square {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        isOpaque = false

        let path: UIBezierPath
        switch type {
        case .square:
            path = UIBezierPath(rect: rect)
        case .arrow:
            path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))

            let rectangleBottom = rect.maxY - 20
            path.addLine(to: CGPoint(x: rect.maxX, y: rectangleBottom))
            path.addLine(to: CGPoint(x: 2.0 / 3.0 * rect.maxX, y: rectangleBottom))
            path.addLine(to: CGPoint(x: rect.maxX / 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: 1.0 / 3.0 * rect.maxX, y: rectangleBottom))
            path.addLine(to: CGPoint(x: 0, y: rectangleBottom))
            path.close()
        }

        color.setFill()
        path.fill()
    }
}
