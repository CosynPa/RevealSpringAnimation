//
//  NewtonSolver.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/16.
//

import Foundation

struct NewtonSolver {
    struct MaxTry: Error { }

    static func solve(f: (Double) -> Double, df: (Double) -> (Double), x0: Double, epsilon: Double = 1e-8, maxTry: Int = 1000) throws  -> Double {
        var x = x0
        var previous: Double?
        var tryCount = 0
        while previous.flatMap({ previous in abs(previous - x) >= epsilon }) ?? true {
            guard tryCount < maxTry else {
                throw MaxTry()
            }

            tryCount += 1
            previous = x

            var d = df(x)

            if abs(d) < epsilon {
                d = d >= 0 ? epsilon : -epsilon
            }

            x = x - f(x) / d
        }
        return x
    }
}
