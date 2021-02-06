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
    var mimicAnimationRecord: [(TimeInterval, CGFloat)]? {
        didSet { mimicUpdate.send() }
    }

    private var systemUpdate = PassthroughSubject<Void, Never>()
    private var mimicUpdate = PassthroughSubject<Void, Never>()

    var maxDifference: CGFloat {
        guard let system = systemAnimationRecord, system.count > 0 else { return 0 }
        guard let mimic = mimicAnimationRecord, mimic.count > 0 else { return 0 }

        guard mimic.count >= 2 else {
            return abs(mimic[0].1 - system[0].1)
        }

        // Around 1 / 60 for 60 Hz screens
        let frameDuration = (mimic.last!.0 - mimic[0].0) / Double(mimic.count - 1)

        let differences: [CGFloat] = system.compactMap { (systemTime, systemValue) -> CGFloat? in
            let matchedItem: (TimeInterval, CGFloat)? = mimic.first { (mimicTime, _) -> Bool in
                abs(mimicTime - systemTime) < frameDuration / 2
            }

            return matchedItem.map { (_, mimicValue) -> CGFloat in
                abs(mimicValue - systemValue)
            }
        }

        return differences.max() ?? 0
    }

    var maxDifferencePublisher: AnyPublisher<CGFloat, Never> {
        systemUpdate.zip(mimicUpdate)
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
