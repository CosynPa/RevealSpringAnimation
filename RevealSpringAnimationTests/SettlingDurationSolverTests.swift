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
        let curve = SpringCurve(response: 2 * Double.pi / 2, dampingRatio: 1, initialVelocity: 2)

        let t = SettlingDurationSolver.settlingDuration(curve: curve)

        XCTAssertEqual(abs(curve.curveFunc(t) - 1), 1e-3, accuracy: 1e-8)
    }
}
