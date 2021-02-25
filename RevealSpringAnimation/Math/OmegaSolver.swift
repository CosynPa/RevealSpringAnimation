//
//  OmegaSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/21.
//

import Foundation

struct OmegaSolver {
    static let minDuration = 0.01
    static let maxDuration = 10.0

    // Solve |c2| * exp(a * t) = 0.001
    static func underDampingSolve(parameter: UIKitSpring, epsilon: Double) throws -> Double {
        let alpha = 0.001

        let D = min(max(parameter.duration, Self.minDuration), Self.maxDuration)
        let zeta = parameter.dampingRatio
        let v0 = parameter.initialVelocity

        assert(0 < zeta && zeta < 1)

        let u = v0 / zeta
        let E = D * zeta
        let c = alpha * sqrt(1 - zeta * zeta) / zeta

        // The equation becomes | u / omega - 1 | * exp(-E * omega) = c

        if abs(u) < epsilon {
            if c < 1 {
                return -log(c) / E
            } else {
                // zeta is too small, c2 is too small, we don't know the system formula for this case
                return 10000
            }
        } else {
            let f = { (omega: Double) -> Double in
                (u / omega - 1) * exp(-E * omega)
            }

            let df = { (omega: Double) -> Double in
                (-u / omega / omega - E * u / omega + E) * exp(-E * omega)
            }

            // ddf = (2u / omega^3 + 2EU / omega^2 + E^2 u / omega - E^2) exp(-E omega)

            if u < 0 {
                // Derivative always positive, the second order derivative always negative, can use Newton solver

                var x0 = 1.0

                while f(x0) >= -c {
                    x0 /= 2.0
                }

                return try NewtonSolver.solve(f: { omega in f(omega) + c }, df: df, x0: x0, epsilon: epsilon)
            } else {
                let minimumPoint = 1 / (-E / 2 + sqrt(E * E / 4 + E / u))

                if abs(f(minimumPoint) + c) < epsilon {
                    return minimumPoint
                } else if f(minimumPoint) < -c {
                    func inflectionPoint() -> Double {
                        let a = 2 * u
                        let b = 2 * E * u
                        let c = E * E * u
                        let d = -E * E

                        do {
                            let x = try CubicEquation.singleRoot(a: a, b: b, c: c, d: d)
                            return 1 / x
                        } catch {
                            print(error) // Should not happen
                            return 1
                        }
                    }

                    let inflection = inflectionPoint()

                    if minimumPoint > inflection {
                        // Should not happend
                        print("minimumPoint \(minimumPoint) greater than inflection \(inflection)")
                    }

                    return try NewtonSolver.solve(f: { omega in f(omega) + c }, df: df, x0: inflectionPoint(), epsilon: epsilon)
                } else {
                    var x0 = u // f(u) = 0

                    while f(x0) <= c {
                        x0 /= 2.0
                    }

                    return try NewtonSolver.solve(f: { omega in f(omega) - c }, df: df, x0: x0, epsilon: epsilon)
                }
            }
        }
    }

    static func criticalDampingSolve(parameter: UIKitSpring, epsilon: Double) throws -> Double {
        let alpha = 0.001

        let D = min(max(parameter.duration, Self.minDuration), Self.maxDuration)
        let zeta = parameter.dampingRatio
        let v0 = parameter.initialVelocity

        assert(abs(zeta - 1) < epsilon)

        let a = -1 + v0 * D

        // w = D * omega, solve |f(w)| = alpha
        let f = { (w: Double) -> Double in
            (a - w) * exp(-w)
        }

        let df = { (w: Double) -> Double in
            (w - a - 1) * exp(-w)
        }

        // ddf = (-w + a + 2) * exp(-w)

        let minimumPoint = a + 1
        let inflectionPoint = a + 2

        let w_solution: Double

        if minimumPoint <= 0 {
            assert(alpha < 1)
            // min f(w) = f(0) = a < -1 < -alpha, has solution in (0, +inf)
            if inflectionPoint > 0 {
                w_solution = try NewtonSolver.solve(f: { w in f(w) + alpha }, df: df, x0: inflectionPoint)
            } else {
                // Theoretical we can still use inflectionPoint as x0, but that number may be too small causing +inf in calculation.
                w_solution = try NewtonSolver.solve(f: { w in f(w) + alpha }, df: df, x0: 0)
            }
        } else {
            let minValue = f(minimumPoint) // = -exp(-a -1)

            if abs(minValue + alpha) < epsilon {
                w_solution = minimumPoint
            } else if minValue < -alpha {
                w_solution = try NewtonSolver.solve(f: { w in f(w) + alpha }, df: df, x0: inflectionPoint)
            } else {
                assert(alpha < -log(alpha) - 1, "Unsupported alpha \(alpha)")
                // f(minimumPoint) = -exp(-a - 1) > -alpha, implies a > -ln(alpha) - 1
                // max f(w) = f(0) = a > -ln(alpha) - 1 > alpha, has solution in (0, a)

                var x0 = a
                while f(x0) < alpha {
                    x0 /= 2
                }

                w_solution = try NewtonSolver.solve(f: {w in f(w) - alpha }, df: df, x0: x0)
            }
        }

        return w_solution / D
    }

    static func omega(parameter: UIKitSpring, epsilon: Double = 1e-8) -> Double {
        let zeta = parameter.dampingRatio

        do {
            if zeta < epsilon {
                return 1
            } else if zeta < 1 - epsilon {
                return try underDampingSolve(parameter: parameter, epsilon: epsilon)
            } else {
                // UIKit API doesn't allow damping ratio that is greater than 1
                var OneDampingRatio = parameter
                OneDampingRatio.dampingRatio = 1
                return try criticalDampingSolve(parameter: OneDampingRatio, epsilon: epsilon)
            }
        } catch {
            print("Solve omega error \(error)")
            return 1
        }
    }
}
