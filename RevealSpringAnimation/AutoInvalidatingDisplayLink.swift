//
//  AutoInvalidatingDisplayLink.swift
//  PVT
//
//  Created by Pan Yusheng on 2019/1/7.
//  Copyright © 2019 Pan Yusheng. All rights reserved.
//

import Foundation
import UIKit

// The display link will be invalidated automatically if no one has a strong reference to the AutoInvalidatingDisplayLink.
// But be careful, objects of this class have a strong reference to the callback.
public class AutoInvalidatingDisplayLink {
    public let link: CADisplayLink
    public var callback: ((CADisplayLink) -> Void)? {
        didSet {
            target.callback = callback
        }
    }

    private let target: DisplayLinkTarget

    public init(add: Bool = true) {
        target = DisplayLinkTarget()
        link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.step(link:)))

        if add {
            link.add(to: .main, forMode: .default)
        }
    }

    deinit {
        link.invalidate()
    }
}

fileprivate class DisplayLinkTarget {
    var callback: ((CADisplayLink) -> Void)?

    @objc func step(link: CADisplayLink) {
        callback?(link)
    }
}
