//
//  SettlingDuratinoSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/17.
//

import Foundation

// Find the largest solution x that |x(x)| = alpha where x is the position from the equilibrium position.
struct SettlingDurationSolver {
    static func criticalDampingSolve(curve: SpringCurve, alpha: Double = 1e-3, epsilon: Double = 1e-8) -> Double {
        assert(curve.dampingRatio == 1.0)
        assert(alpha < 1)

        let v0 = curve.initialVelocity
        let omega = curve.omega

        let c2 = v0 - omega

        if abs(c2) < epsilon {
            // The equation becomes x(t) = -exp(-omega * t)
            return -log(alpha) / curve.omega
        } else {
            // x''(t2) = 0, the inflection point
            let t2 = (2 * c2 + omega) / omega / c2

            if abs(curve.curveFunc(t2) - 1) > alpha {
                // The sign of x''(t) doesn't change when t > t2, can use Newton's method

                let f: (Double) -> Double
                if c2 < 0 {
                    f = { t in curve.curveFunc(t) - 1 + alpha }
                } else {
                    f = { t in curve.curveFunc(t) - 1 - alpha }
                }

                return NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: t2)
            } else {
                // x'(t1) = 0, the turning point
                let t1 = t2 - 1 / omega

                let f: (Double) -> Double = { t in abs(curve.curveFunc(t) - 1) - alpha }

                if abs(curve.curveFunc(t1) - 1) > alpha {
                    // |x(t1)| > alpha, |x(t2)| <= alpha, has solution between t1 and t2
                    // Since t1 is the turning point, the solution is unique
                    return BinarySearchSolver.solve(f: f, x1: t1, x2: t2)
                } else {
                    // |x(0)| = 1 > alpha, |x(t1)| <= alpha, has solution between 0 and t1
                    // Since t1 is the turning point, the solution is unique
                    assert(c2 > 0)
                    return BinarySearchSolver.solve(f: f, x1: 0, x2: t1)
                }
            }
        }
    }

    static func settlingDuration(curve: SpringCurve, alpha: Double = 1e-3) -> Double {
        if curve.dampingRatio == 1.0 {
            return Self.criticalDampingSolve(curve: curve, alpha: alpha)
        } else {
            // TODO
            return 0
        }
    }
}
