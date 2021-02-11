//
//  KeyboardInfo.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/11.
//

import Foundation
import UIKit

struct KeyboardInfo {
    var endFrame = CGRect.zero
    var animate = false

    init(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }

        guard let endFrame = userInfo[UIView.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIView.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        self.endFrame = endFrame
        self.animate = duration > 0.0
    }
}
