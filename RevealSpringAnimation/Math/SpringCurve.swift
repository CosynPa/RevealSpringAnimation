//
//  SpringCurve.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/11.
//

import Foundation

// Mathematical representation of a spring curve
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

    func stiffness(mass: Double = 1.0) -> Double {
        mass * omega * omega
    }

    func damping(mass: Double = 1.0) -> Double {
        dampingRatio * 2 * sqrt(stiffness(mass: mass) * mass)
    }

    var settlingDuration: Double {
        return SettlingDurationSolver.settlingDuration(curve: self, alpha: 1e-3, epsilon: 1e-8)
    }

    init(response: Double, dampingRatio: Double, initialVelocity: Double) {
        _response = response
        _dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }

    init(_ p: Spring) {
        self.init(response: p.response, dampingRatio: p.dampingFraction, initialVelocity: 0.0)
    }

    init(_ p: InterpolatingSpring) {
        let response = 2 * Double.pi / sqrt(p.stiffness / max(1e-5, p.mass))
        let dampingRatio = min(1.0, p.damping / 2 / sqrt(p.stiffness * p.mass))
        self.init(response: response,
                  dampingRatio: dampingRatio,
                  initialVelocity: p.initialVelocity)
    }

    init(_ p: UIKitSpring) {
        self.init(response: 2 * Double.pi / OmegaSolver.omega(parameter: p),
                  dampingRatio: min(1.0, p.dampingRatio),
                  initialVelocity: p.initialVelocity)
    }

    init(_ p: CASpring) {
        let response = 2 * Double.pi / sqrt(p.stiffness / max(1e-5, p.mass))
        var dampingRatio = p.damping / 2 / sqrt(p.stiffness * p.mass)
        dampingRatio = min(1.0, dampingRatio)
        self.init(response: response,
                  dampingRatio: dampingRatio,
                  initialVelocity: p.initialVelocity)
    }

    static func makeKeyboardSpring() -> SpringCurve {
        SpringCurve(response: 2 * Double.pi / 18, dampingRatio: 1, initialVelocity: 0)
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
            let c2 = (v0 + a) / b
            let theta = atan(c2)
            y = sqrt(1 + c2 * c2) * exp(a * t) * cos(b * t + theta + Double.pi)
        }

        return y + 1
    }

    func derivativeCurveFunc(_ t: Double) -> Double {
        let v0 = initialVelocity
        let zeta = dampingRatio

        if zeta == 1.0 {
            let c1 = -1.0
            let c2 = v0 - omega
            return (c2 - omega * c1 - omega * c2 * t) * exp(-omega * t)
        } else if zeta > 1 {
            let s1 = omega * (-zeta + sqrt(zeta * zeta - 1))
            let s2 = omega * (-zeta - sqrt(zeta * zeta - 1))
            let c1 = (-s2 - v0) / (s2 - s1)
            let c2 = (s1 + v0) / (s2 - s1)
            return c1 * s1 * exp(s1 * t) + c2 * s2 * exp(s2 * t)
        } else {
            let a = -omega * zeta
            let b = omega * sqrt(1 - zeta * zeta)
            let c2 = (v0 + a) / b
            let theta = atan(c2)
            return sqrt(1 + c2 * c2) * exp(a * t) * (a * cos(b * t + theta + Double.pi) - b * sin(b * t + theta + Double.pi))
        }
    }
}
