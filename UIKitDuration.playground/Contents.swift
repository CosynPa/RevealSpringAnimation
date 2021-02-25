import UIKit

// UIView spring animate API parameters
struct UIKitSpring {
    var duration: Double = 0.5
    var dampingRatio: Double = 1.0
    var initialVelocity: Double = 0.0
}

// CASpringAnimation API parameters
struct CASpring {
    var mass: Double = 1.0
    var stiffness: Double = 1.0
    var damping: Double = 1.0
    var initialVelocity: Double = 0.0

    var omega: Double {
        sqrt(stiffness / mass)
    }

    var dampingRatio: Double {
        damping / 2 / sqrt(stiffness * mass)
    }
}

func convert(uiValue: UIKitSpring) -> CASpring {
    let view = UIView(frame: .zero)

    UIView.animate(withDuration: uiValue.duration,
                   delay: 0,
                   usingSpringWithDamping: CGFloat(uiValue.dampingRatio),
                   initialSpringVelocity: CGFloat(uiValue.initialVelocity),
                   options: []) {
        view.frame = CGRect(origin: CGPoint(x: 1, y: 0), size: .zero)
    }

    let caAnimation = view.layer.animation(forKey: "position") as! CASpringAnimation

    return CASpring(mass: Double(caAnimation.mass),
                    stiffness: Double(caAnimation.stiffness),
                    damping: Double(caAnimation.damping),
                    initialVelocity: Double(caAnimation.initialVelocity))
}

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

func inflectionPoint(u: Double, E: Double) -> Double {
    let a = 2 * u
    let b = 2 * E * u
    let c = E * E * u
    let d = -E * E

    do {
        let x = try CubicEquation.singleRoot(a: a, b: b, c: c, d: d)
        return 1 / x
    } catch {
        return 1
    }
}

let v0s = stride(from: 4.8, to: 4.9, by: 0.001)
let omegas = v0s.map { v0 -> Double in
    let uiValue = UIKitSpring(duration: 1, dampingRatio: 1, initialVelocity: v0)
    let caValue = convert(uiValue: uiValue)

    return caValue.omega
}

for (v0, omega) in zip(v0s, omegas) {
    let i = Int(round(v0 * 10000))
    print("(\(i), \(omega)),")
}
