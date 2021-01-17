//
//  SettlingDurationSolverTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/1/17.
//

import XCTest
@testable import RevealSpringAnimation

class SettlingDurationSolverTests: XCTestCase {
    func testCriticalDamping() throws {
        let parameters: [(omega: Double, dampingRatio: Double, v0: Double)] = [
            (2, 1, 2), // c2 = 0
            (2, 1, -1), // c2 < 0
            (2, 1, 4), // c2 > 0
        ]

        for p in parameters {
            let curve = SpringCurve(response: 2 * Double.pi / p.omega, dampingRatio: p.dampingRatio, initialVelocity: p.v0)

            let alpha = 1e-3
            let t = SettlingDurationSolver.criticalDampingSolve(curve: curve, alpha: alpha)
            testSolution(t: t, curve: curve, alpha: alpha)

            let alpha2 = 0.8
            let t2 = SettlingDurationSolver.criticalDampingSolve(curve: curve, alpha: alpha2)
            testSolution(t: t2, curve: curve, alpha: alpha2)
        }
    }

    func testCriticalDampingSmallInflectionPoint() throws {
        let omega = 2.0
        let curve = SpringCurve(response: 2 * Double.pi / omega, dampingRatio: 1, initialVelocity: 4)

        // The turning point
        let t1 = 1.0
        assert(abs(curve.derivativeCurveFunc(t1)) < 1e-6)
        assert(abs(curve.curveFunc(t1) - 1.1353) < 1e-4)

        // The inflection point
        let t2 = 1.5
        assert(abs(curve.curveFunc(t2) - 1.0996) < 1e-4)

        // When the value at t2 is less than alpha
        let alpha1 = 0.12
        let t_alpha1 = SettlingDurationSolver.criticalDampingSolve(curve: curve, alpha: alpha1)
        testSolution(t: t_alpha1, curve: curve, alpha: alpha1)

        // When the value at t1 is less than alpha
        let alpha2 = 0.15
        let t_alpha2 = SettlingDurationSolver.criticalDampingSolve(curve: curve, alpha: alpha2)
        testSolution(t: t_alpha2, curve: curve, alpha: alpha2)
    }

    func testALot() throws {
        let omegas = [1.0, 10.0]
        let dampingRatios = [1.0]
        let v0s = stride(from: -100.0, through: 100.0, by: 10.0)
        let alphas = stride(from: 0.001, to: 0.9, by: 0.02)

        for omega in omegas {
            for d in dampingRatios {
                for v0 in v0s {
                    for alpha in alphas {
                        let curve = SpringCurve(response: 2 * Double.pi / omega, dampingRatio: d, initialVelocity: v0)
                        let t = SettlingDurationSolver.settlingDuration(curve: curve, alpha: alpha)
                        testSolution(t: t, curve: curve, alpha: alpha)
                    }
                }
            }
        }

    }

    func testSolution(t: Double, curve: SpringCurve, alpha: Double) {
        XCTAssertEqual(abs(curve.curveFunc(t) - 1), alpha, accuracy: 1e-6)

        let step = 0.01 * curve.response
        for t2 in stride(from: t + step, to: t + 50 * curve.response, by: step) {
            XCTAssertLessThan(abs(curve.curveFunc(t2) - 1), alpha)
        }
    }
}
