//
//  CubicEquationTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/2/23.
//

import XCTest
@testable import RevealSpringAnimation

class CubicEquationTests: XCTestCase {
    func test() throws {
        for a in [-2.0, 1.0, 2.0, 10.0] {
            for b in stride(from: -30.0, to: 30.0, by: 1.0) {
                for c in stride(from: -30.0, to: 30.0, by: 1.0) {
                    for d in stride(from: -30.0, to: 30.0, by: 1.0) {
                        do {
                            let x = try CubicEquation.singleRoot(a: a, b: b, c: c, d: d)
                            XCTAssertEqual(a * x * x * x + b * x * x + c * x + d, 0, accuracy: 1e-8)
                        } catch is CubicEquation.ThreeRootsError {

                        }
                    }
                }
            }
        }
    }

    func testNegativeCubeRoot() throws {
        let x = try CubicEquation.singleRoot(a: 1, b: 0, c: 0, d: 8)
        XCTAssertEqual(x, -2, accuracy: 1e-8)
    }
}
