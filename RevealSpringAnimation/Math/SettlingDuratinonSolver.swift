//
//  SettlingDuratinoSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/17.
//

import Foundation

// Find the largest solution x that |f(x)| = alpha where f is the position from the equilibrium position.
struct SettlingDurationSolver {
    private static func criticalDampingSolve(curve: SpringCurve, alpha: Double = 1e-3, epsilon: Double = 1e-8) -> Double {
        assert(curve.dampingRatio == 1.0)

        let c2 = curve.initialVelocity - curve.omega

        if abs(c2) < epsilon {
            // The equation becomes x(t) = -exp(-omega * t)
            return -log(alpha) / curve.omega
        } else {
            // TODO
            return 0
        }
    }

    static func settlingDuration(curve: SpringCurve) -> Double {
        if curve.dampingRatio == 1.0 {
            return Self.criticalDampingSolve(curve: curve)
        } else {
            // TODO
            return 0
        }
    }
}
