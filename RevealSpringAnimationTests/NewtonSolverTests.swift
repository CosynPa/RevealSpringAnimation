//
//  RevealSpringAnimationTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/1/17.
//

import XCTest
@testable import RevealSpringAnimation

class NewtonSolverTests: XCTestCase {
    func testBasic() throws {
        let f: (Double) -> Double = { x in x * x - 2.0 }
        let df: (Double) -> Double = { x in 2 * x }

        let x0 = NewtonSolver.solve(f: f, df: df, x0: 3)

        XCTAssertEqual(x0, sqrt(2), accuracy: 1e-8)
    }

    func testNegativeDerivative() throws {
        let f: (Double) -> Double = { x in x * x - 2.0 }
        let df: (Double) -> Double = { x in 2 * x }

        let x0 = NewtonSolver.solve(f: f, df: df, x0: -3)

        XCTAssertEqual(x0, -sqrt(2), accuracy: 1e-8)
    }
}
