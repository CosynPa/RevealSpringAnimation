//
//  CubicEquation.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/23.
//

import Foundation

struct CubicEquation {
    struct ThreeRootsError: Error {}
    struct ZeroCoefficientError: Error {}

    // The root of x^3 + px + q = 0
    static func singleRoot(p: Double, q: Double) throws -> Double {
        func cubeRoot(_ x: Double) -> Double {
            x >= 0 ? pow(x, 1.0 / 3.0) : -pow(-x, 1.0 / 3.0)
        }

        let delta = -(q * q / 4 + p * p * p / 27)
        if delta <= 0 {
            return cubeRoot(-q / 2 + sqrt(-delta)) + cubeRoot(-q / 2 - sqrt(-delta))
        } else {
            throw ThreeRootsError()
        }
    }

    // The root of ax^3 + bx^2 + cx + d = 0
    static func singleRoot(a: Double, b: Double, c: Double, d: Double) throws -> Double {
        guard a != 0 else { throw ZeroCoefficientError() }

        let p = (3 * a * c - b * b) / (3 * a * a)
        let q = (27 * a * a * d - 9 * a * b * c + 2 * b * b * b) / (27 * a * a * a)

        return try Self.singleRoot(p: p, q: q) - b / 3 / a
    }
}
