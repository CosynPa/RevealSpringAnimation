//
//  AlternativeFormulaTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/2/25.
//

import XCTest
@testable import RevealSpringAnimation

extension SpringCurve {
    func alternativeCurveFunc(_ t: Double) -> Double {
        let v0 = initialVelocity
        let zeta = dampingRatio

        assert(zeta < 1)

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        let y = (-cos(b * t) + c2 * sin(b * t)) * exp(a * t)
        return y + 1
    }
}

class AlternativeFormulaTests: XCTestCase {
    func test() {
        for response in stride(from: 1.0, to: 5.0, by: 0.5) {
            for zeta in stride(from: 0.0, to: 0.9, by: 0.1) {
                for v0 in stride(from: -5.0, to: 5.0, by: 1.0) {
                    for t in stride(from: 0.0, to: 10.0, by: 0.5) {
                        let curve = SpringCurve(response: response, dampingRatio: zeta, initialVelocity: v0)

                        XCTAssertEqual(curve.curveFunc(t), curve.alternativeCurveFunc(t), accuracy: 1e-10)
                    }
                }
            }
        }
    }
}
