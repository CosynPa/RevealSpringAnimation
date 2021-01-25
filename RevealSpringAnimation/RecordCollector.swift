//
//  RecordCollector.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/25.
//

import Foundation
import UIKit
import Combine

class RecordCollector {
    static var shared = RecordCollector()

    var printRecord = true

    var systemAnimationRecord: [(TimeInterval, CGFloat)]? {
        didSet {
            if let record = systemAnimationRecord, printRecord {
                print(record)
            }
            systemUpdate.send()
        }
    }
    var customAnimationRecord: [(TimeInterval, CGFloat)]? {
        didSet { customUpdate.send() }
    }

    private var systemUpdate = PassthroughSubject<Void, Never>()
    private var customUpdate = PassthroughSubject<Void, Never>()

    var maxDifference: CGFloat {
        guard let system = systemAnimationRecord, system.count > 0 else { return 0 }
        guard let custom = customAnimationRecord, custom.count > 0 else { return 0 }

        guard custom.count >= 2 else {
            return abs(custom[0].1 - system[0].1)
        }

        // Around 1 / 60 for 60 Hz screens
        let frameDuration = (custom.last!.0 - custom[0].0) / Double(custom.count - 1)

        let differences: [CGFloat] = system.compactMap { (systemTime, systemValue) -> CGFloat? in
            let matchedItem: (TimeInterval, CGFloat)? = custom.first { (customTime, _) -> Bool in
                abs(customTime - systemTime) < frameDuration / 2
            }

            return matchedItem.map { (_, customValue) -> CGFloat in
                abs(customValue - systemValue)
            }
        }

        return differences.max() ?? 0
    }

    var maxDifferencePublisher: AnyPublisher<CGFloat, Never> {
        systemUpdate.zip(customUpdate)
            .map { [weak self] _ -> CGFloat in
                self?.maxDifference ?? 0
            }
            .eraseToAnyPublisher()
    }

    init() {
        maxDifferencePublisher.subscribe(Subscribers.Sink(receiveCompletion: { _ in

        }, receiveValue: { [weak self] (diff) in
            if self?.printRecord ?? false {
                print("Difference \(diff)")
            }
        }))
    }
}
