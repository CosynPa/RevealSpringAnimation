//
//  UIKitDurationTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/2/21.
//

import XCTest
@testable import RevealSpringAnimation

extension SpringCurve {
    // The time t such that |c2| * exp(a * t) = 0.001
    var estimatedDuration: Double {
        assert(0 < dampingRatio && dampingRatio < 1)

        let v0 = initialVelocity
        let zeta = dampingRatio

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        // c2 should not equal to 0 if omega is found by OmegaSolver, since omega satisfies |c2| * exp(a * t) = 0.001
        return log(0.001 / abs(c2)) / a
    }
}

class UIKitDurationTests: XCTestCase {
    func testSolution(parameter: UIKitSpring) {
        let spring = SpringCurve(parameter)
        let systemSpring = SpringCurve(SystemUIKitAnimationConverter.convert(uiValue: parameter))

        XCTAssertEqual(spring.estimatedDuration, parameter.duration, accuracy: 1e-8)
        XCTAssertEqual(spring.omega, systemSpring.omega, accuracy: 1e-4)
    }

    func testALot() {
        let durations = [1.0, 3.0]
        let dampingRatios = stride(from: 0.1, to: 1.0, by: 0.1)
        let v0s = stride(from: -10.0, to: 0, by: 0.2)

        for d in durations {
            for zeta in dampingRatios {
                for v0 in v0s {
                    testSolution(parameter: UIKitSpring(duration: d, dampingRatio: zeta, initialVelocity: v0))
                }
            }
        }
    }
}
