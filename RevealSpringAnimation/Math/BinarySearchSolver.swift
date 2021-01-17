//
//  BinarySearchSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/17.
//

import Foundation

struct BinarySearchSolver {
    static func solve(f: (Double) -> Double, x1: Double, x2: Double, epsilon: Double = 1e-8) -> Double {
        guard f(x1) != 0 else {
            return x1
        }

        guard f(x2) != 0 else {
            return x2
        }

        guard f(x1) * f(x2) < 0 else {
            // Can't find the solution
            return x1
        }

        guard x1 != x2 else {
            return x1
        }

        var x1 = x1 < x2 ? x1 : x2
        var x2 = x1 < x2 ? x2 : x1

        while x2 - x1 > epsilon {
            let mid = (x1 + x2) / 2

            if f(mid) == 0 {
                return mid
            } else {
                if f(x1) * f(mid) < 0 {
                    x2 = mid
                } else {
                    x1 = mid
                }
            }
        }

        return x1
    }
}
