//
//  OmegaSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/21.
//

import Foundation

struct OmegaSolver {
    // Solve |c2| * exp(a * t) = 0.001
    static func underDampingSolve(parameter: UIKitSpring, epsilon: Double) throws -> Double {
        let alpha = 0.001

        let D = parameter.duration
        let zeta = parameter.dampingRatio
        let v0 = parameter.initialVelocity

        assert(0 < zeta && zeta < 1)

        let u = v0 / zeta
        let E = D * zeta
        let c = alpha * sqrt(1 - zeta * zeta) / zeta

        // The equation becomes | u / omega - 1 | * exp(-E * omega) = c

        if abs(u) < epsilon {
            return -log(c) / E
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
                return try NewtonSolver.solve(f: { omega in f(omega) + c }, df: df, x0: 1.0, epsilon: epsilon)
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

    static func omega(parameter: UIKitSpring, epsilon: Double = 1e-8) -> Double {
        let zeta = parameter.dampingRatio

        do {
            if zeta < epsilon {
                return 1
            } else if zeta < 1 - epsilon {
                return try underDampingSolve(parameter: parameter, epsilon: epsilon)
            } else {
                // TODO
                return 1
            }
        } catch {
            return 1
        }
    }
}
