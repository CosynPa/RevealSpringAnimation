//
//  CurveMixer.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/24.
//

import Foundation
import UIKit

protocol MotionFunction {
    func value(at t: Double) -> CGFloat
    func velocity(at t: Double) -> CGFloat
    var settlingDuration: Double { get }
}

struct SimpleCurve: MotionFunction {
    var curve: SpringCurve
    var from: CGFloat
    var to: CGFloat

    func value(at t: Double) -> CGFloat {
        from + (to - from) * CGFloat(curve.curveFunc(t))
    }

    func velocity(at t: Double) -> CGFloat {
        (to - from) * CGFloat(curve.derivativeCurveFunc(t))
    }

    var settlingDuration: Double {
        curve.settlingDuration
    }
}

struct ComposedCurve: MotionFunction {
    var previous: MotionFunction
    // The start time of the current animation relative to the start time of the previous animation
    var startOffset: Double
    var curve: SpringCurve
    var to: CGFloat

    func value(at t: Double) -> CGFloat {
        let previousValue = previous.value(at: t + startOffset)
        return previousValue + (to - previousValue) * CGFloat(curve.curveFunc(t))
    }

    func velocity(at t: Double) -> CGFloat {
        previous.velocity(at: t + startOffset) * (1 - CGFloat(curve.curveFunc(t))) + (to - previous.value(at: t + startOffset)) * CGFloat(curve.derivativeCurveFunc(t))
    }

    var settlingDuration: Double {
        max(previous.settlingDuration - startOffset, curve.settlingDuration)
    }
}

struct KeepVelocityCurve: MotionFunction {
    var previous: MotionFunction
    // The start time of the current animation relative to the start time of the previous animation
    var startOffset: Double
    var curve: SpringCurve
    var to: CGFloat

    private var newFrom: CGFloat
    private var newCurve: SpringCurve

    init(previous: MotionFunction, startOffset: Double, curve: SpringCurve, to: CGFloat) {
        self.previous = previous
        self.startOffset = startOffset
        self.curve = curve
        self.to = to

        newFrom = previous.value(at: startOffset)

        let normalizedVelocity = previous.velocity(at: startOffset) / (abs(to - newFrom) < 0.001 ? 0.001 : to - newFrom)
        newCurve = SpringCurve(response: curve.response,
                               dampingRatio: curve.dampingRatio,
                               initialVelocity: curve.initialVelocity + Double(normalizedVelocity))
    }

    func value(at t: Double) -> CGFloat {
        SimpleCurve(curve: newCurve, from: newFrom, to: to).value(at: t)
    }

    func velocity(at t: Double) -> CGFloat {
        SimpleCurve(curve: newCurve, from: newFrom, to: to).velocity(at: t)
    }

    var settlingDuration: Double {
        newCurve.settlingDuration
    }
}
