//
//  DerivativeTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/1/17.
//

import XCTest
@testable import RevealSpringAnimation

class DerivativeTests: XCTestCase {
    func test() throws {
        let responses = [1.0, 2.0, 3.0]
        let dampingRatios = [0.2, 0.8, 1.0, 1.5, 3.0]
        let initialVelocities = [-10.0, -5, -1, 0, 1, 5, 10]

        let ts = stride(from: 0, to: 100, by: 0.1)

        for r in responses {
            for d in dampingRatios {
                for v in initialVelocities {
                    for t in ts {
                        let curve = SpringCurve(response: r, dampingRatio: d, initialVelocity: v)

                        let df = curve.derivativeCurveFunc(t)
                        let estimatedDf = Self.estimateDerivative(f: curve.curveFunc, x: t)

                        XCTAssertEqual(df, estimatedDf, accuracy: 1e-6)
                    }
                }
            }
        }
    }

    static func estimateDerivative(f: (Double) -> Double, x: Double) -> Double {
        let delta = 1e-6

        return (f(x + delta) - f(x - delta)) / 2 / delta
    }
}
