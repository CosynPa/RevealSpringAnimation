//
//  SettlingDuratinoSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/17.
//

import Foundation

// Representing points x + k * step for any integer k
struct Stride {
    var x: Double
    var step: Double

    subscript(k: Int) -> Double {
        x + Double(k) * step
    }
}

// Find the largest solution x that |x(x)| = alpha where x is the position from the equilibrium position.
struct SettlingDurationSolver {
    static func criticalDampingSolve(curve: SpringCurve, alpha: Double, epsilon: Double = 1e-8) throws -> Double {
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

                return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: t2)
            } else {
                // x'(t1) = 0, the turning point
                let t1 = t2 - 1 / omega

                if abs(curve.curveFunc(t1) - 1) == alpha {
                    return t1
                } else if abs(curve.curveFunc(t1) - 1) > alpha {
                    // |x(t1)| > alpha, |x(t2)| <= alpha, has solution between t1 and t2
                    // Since t1 is the turning point, the solution is unique

                    let f: (Double) -> Double
                    if c2 < 0 {
                        f = { t in curve.curveFunc(t) - 1 + alpha }
                    } else {
                        f = { t in curve.curveFunc(t) - 1 - alpha }
                    }

                    return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: t2)
                } else {
                    // |x(0)| = 1 > alpha, |x(t1)| <= alpha, has solution between 0 and t1
                    // Since t1 is the turning point, the solution is unique

                    assert(c2 > 0) // because if c2 < 0, x(t1) < -1

                    let f: (Double) -> Double = { t in curve.curveFunc(t) - 1 + alpha }
                    return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: 0)
                }
            }
        }
    }

    static func underDampingTurningPoints(of curve: SpringCurve, epsilon: Double = 1e-8) -> Stride {
        assert(curve.dampingRatio < 1.0)

        let omega = curve.omega
        let zeta = curve.dampingRatio
        let v0 = curve.initialVelocity

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        let phi = atan2(-b - c2 * a, v0)
        return Stride(x: (-phi + Double.pi / 2) / b, step: Double.pi / b)
    }

    static func underDampingInflectionPoints(of curve: SpringCurve, epsilon: Double = 1e-8) -> Stride {
        assert(curve.dampingRatio < 1.0)

        let omega = curve.omega
        let zeta = curve.dampingRatio
        let v0 = curve.initialVelocity

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        let psi = atan2(-2 * a * b - c2 * a * a + c2 * b * b, -a * a + b * b + 2 * c2 * a * b)
        return Stride(x: (-psi + Double.pi / 2) / b, step: Double.pi / b)
    }

    static func settlingDuration(curve: SpringCurve, alpha: Double = 1e-3) -> Double {
        do {
            if curve.dampingRatio == 1.0 {
                return try Self.criticalDampingSolve(curve: curve, alpha: alpha)
            } else {
                // TODO
                return 0
            }
        } catch {
            return 0
        }
    }
}
