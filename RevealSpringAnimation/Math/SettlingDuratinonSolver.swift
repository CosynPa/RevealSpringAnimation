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

    // The largest k such that x + k * step <= y
    func k(before y: Double) -> Int {
        assert(step > 0)
        
        return Int(floor((y - x) / step))
    }
}

// Find the largest solution x that |x(x)| = alpha where x is the position from the equilibrium position.
struct SettlingDurationSolver {
    static func criticalOverDampingSolve(curve: SpringCurve, alpha: Double, epsilon: Double) throws -> Double {
        assert(curve.dampingRatio > 1 - epsilon)
        assert(0 < alpha && alpha < 1)

        let omega = curve.omega
        let zeta = curve.dampingRatio
        let v0 = curve.initialVelocity

        // x'(turning) = 0, the turning point, x''(inflection) = 0, the inflection point
        let points: (turning: Double, inflection: Double)?
        let increaseToInfinity: Bool // Whether x'(t) > 0 for t > t1

        let criticalDamping = abs(zeta - 1) < epsilon
        if criticalDamping {
            let c2 = v0 - omega

            if abs(c2) < epsilon {
                // The equation becomes x(t) = -exp(-omega * t)
                return -log(alpha) / curve.omega
            }

            let inflection = (2 * c2 + omega) / omega / c2
            let turning = inflection - 1 / omega

            points = (turning, inflection)
            increaseToInfinity = c2 < 0
        } else {
            let s1 = omega * (-zeta + sqrt(zeta * zeta - 1))
            let s2 = omega * (-zeta - sqrt(zeta * zeta - 1))
            let c1 = (-s2 - v0) / (s2 - s1)
            let c2 = (s1 + v0) / (s2 - s1)

            if abs(c1) < epsilon {
                // The equation becomes x(t) = c2 * exp(s2 * t)
                return log(-alpha / c2) / s2
            } else if abs(c2) < epsilon {
                // The equation becomes x(t) = c1 * exp(s1 * t)
                return log(-alpha / c1) / s1
            }

            if c1 * c2 < 0 {
                let turning = log(-c2 * s2 / c1 / s1) / (s1 - s2)
                let inflection = log(-c2 * s2 * s2 / c1 / s1 / s1) / (s1 - s2)
                points = (turning, inflection)
                increaseToInfinity = c1 < 0
            } else {
                points = nil
                increaseToInfinity = true
            }
        }

        if let points = points {
            if abs(curve.curveFunc(points.turning) - 1) == alpha {
                return points.turning
            } else if abs(curve.curveFunc(points.turning) - 1) > alpha {
                // |x(turning)| > alpha, has solution between `turning` and infinity
                // Since `turning` is the turning point, the solution is unique

                let f: (Double) -> Double
                if increaseToInfinity {
                    f = { t in curve.curveFunc(t) - 1 + alpha }
                } else {
                    f = { t in curve.curveFunc(t) - 1 - alpha }
                }

                return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: points.inflection)
            } else {
                // |x(0)| = 1 > alpha, |x(turning)| < alpha, has solution between 0 and `turning`
                // Since `turning` is the turning point, the solution is unique

                // because if increaseToInfinity, decrease to the turning point, so x(turning) < -1
                assert(!increaseToInfinity)

                let f: (Double) -> Double = { t in curve.curveFunc(t) - 1 + alpha }
                return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: 0)
            }
        } else {
            assert(increaseToInfinity)
            let f: (Double) -> Double = { t in curve.curveFunc(t) - 1 + alpha }
            return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: 0)
        }
    }

    static func underDampingTurningPoints(of curve: SpringCurve, epsilon: Double) -> Stride {
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

    static func underDampingInflectionPoints(of curve: SpringCurve, epsilon: Double) -> Stride {
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

    static func underDampingSolve(curve: SpringCurve, alpha: Double, epsilon: Double) throws -> Double {
        assert(curve.dampingRatio < 1.0)
        assert(0 < alpha && alpha < 1)

        let omega = curve.omega
        let zeta = curve.dampingRatio
        let v0 = curve.initialVelocity

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        // For any t >= t3, |x(t)| <= alpha
        let t3 = log(alpha / sqrt(1 + c2 * c2)) / a

        let turningPoints = underDampingTurningPoints(of: curve, epsilon: epsilon)
        let k3 = turningPoints.k(before: t3)

        let k1 = stride(from: k3, to: Int.min, by: -1)
            .first { (i) -> Bool in
                abs(curve.curveFunc(turningPoints[i]) - 1) >= alpha
            }!

        if abs(abs(curve.curveFunc(turningPoints[k1]) - 1) - alpha) < epsilon {
            return turningPoints[k1]
        }

        // The solution is between turningPoints[k1] and turningPoints[k1 + 1]

        let inflectionPoints = underDampingInflectionPoints(of: curve, epsilon: epsilon)
        let k2 = inflectionPoints.k(before: turningPoints[k1 + 1])

        // Because the steps of turningPoints and inflectionPoints are the same
        assert(turningPoints[k1] < inflectionPoints[k2])

        let f: (Double) -> Double
        if  curve.curveFunc(turningPoints[k1]) > 1 {
            f = { t in curve.curveFunc(t) - 1 - alpha }
        } else {
            f = { t in curve.curveFunc(t) - 1 + alpha }
        }

        return try NewtonSolver.solve(f: f, df: curve.derivativeCurveFunc, x0: inflectionPoints[k2])
    }

    static func settlingDuration(curve: SpringCurve, alpha: Double = 1e-3, epsilon: Double = 1e-8) -> Double {
        do {
            if curve.dampingRatio > 1 - epsilon {
                return try Self.criticalOverDampingSolve(curve: curve, alpha: alpha, epsilon: epsilon)
            } else {
                return try Self.underDampingSolve(curve: curve, alpha: alpha, epsilon: epsilon)
            }
        } catch {
            return 0
        }
    }
}
