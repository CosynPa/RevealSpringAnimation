//
//  SystemUIKitAnimationConverter.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/21.
//

import Foundation
import UIKit

struct SystemUIKitAnimationConverter {
    static func convert(uiValue: UIKitSpring) -> CASpring {
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
}
