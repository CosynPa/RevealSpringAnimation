//
//  SpringCurve.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/11.
//

import Foundation

struct SpringCurve {
    private var _response: Double

    var response: Double {
        get {
            max(1e-5, _response)
        }
        set {
            _response = newValue
        }
    }

    private var _dampingRatio: Double

    var dampingRatio: Double {
        get {
            max(0, _dampingRatio)
        }
        set {
            _dampingRatio = newValue
        }
    }
    var initialVelocity: Double

    var omega: Double {
        2 * Double.pi / response
    }

    var settlingDuration: Double {
        // TODO:
        return response
    }

    init(response: Double, dampingRatio: Double, initialVelocity: Double) {
        _response = response
        _dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }

    init(_ p: SpringParameter.Spring) {
        self.init(response: p.response, dampingRatio: p.dampingFraction, initialVelocity: 0.0)
    }

    init(_ p: SpringParameter.InterpolatingSpring) {
        let response = 2 * Double.pi / sqrt(p.stiffness / max(1e-5, p.mass))
        let dampingRatio = p.damping / 2 / sqrt(p.stiffness * p.mass)
        self.init(response: response,
                  dampingRatio: dampingRatio,
                  initialVelocity: p.initialVelocity)
    }

    init(_ p: SpringParameter.UIKitSpring) {
        self.init(response: p.duration, // TODO:
                  dampingRatio: min(1.0, p.dampingRatio),
                  initialVelocity: p.initialVelocity)
    }

    init(_ p: SpringParameter.CASpring) {
        let response = 2 * Double.pi / sqrt(p.stiffness / max(1e-5, p.mass))
        var dampingRatio = p.damping / 2 / sqrt(p.stiffness * p.mass)
        dampingRatio = min(1.0, dampingRatio)
        self.init(response: response,
                  dampingRatio: dampingRatio,
                  initialVelocity: p.initialVelocity)
    }

    func curveFunc(_ t: Double) -> Double {
        let v0 = initialVelocity
        let zeta = dampingRatio

        let y: Double
        if zeta == 1.0 {
            let c1 = -1.0
            let c2 = v0 - omega
            y = (c1 + c2 * t) * exp(-omega * t)
        } else if zeta > 1 {
            let s1 = omega * (-zeta + sqrt(zeta * zeta - 1))
            let s2 = omega * (-zeta - sqrt(zeta * zeta - 1))
            let c1 = (-s2 - v0) / (s2 - s1)
            let c2 = (s1 + v0) / (s2 - s1)
            y = c1 * exp(s1 * t) + c2 * exp(s2 * t)
        } else {
            let a = -omega * zeta
            let b = omega * sqrt(1 - zeta * zeta)
            let c1 = -1.0
            let c2 = (v0 + a) / b
            y = c1 * exp(a * t) * cos(b * t) + c2 * exp(a * t) * sin(b * t)
        }

        return y + 1
    }
}
