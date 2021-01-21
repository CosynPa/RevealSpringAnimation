//
//  SwiftUIView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/20.
//

import SwiftUI
import Combine
import UIKit

struct PropertyRecordView<RecordingValue>: UIViewRepresentable {
    var recorder: PropertyRecorder<RecordingValue>

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        recorder.view = view

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }
}

class PropertyRecorder<RecordingValue> {
    var shouldRecord = true {
        didSet {
            if !shouldRecord {
                endRecord()
            }
        }
    }

    // When calls this function, it should return the current value that you want to record
    var recording: (UIView) -> RecordingValue

    var record: AnyPublisher<[(TimeInterval, RecordingValue)], Never> {
        recordSubject.eraseToAnyPublisher()
    }

    private var recordSubject = PassthroughSubject<[(TimeInterval, RecordingValue)], Never>()

    // Provided by PropertyRecordView, the user should not directly set this property
    fileprivate var view: UIView?

    init(recording: @escaping (UIView) -> RecordingValue) {
        self.recording = recording
    }

    private var start: CFTimeInterval = CACurrentMediaTime()
    private var recordingValues: [(TimeInterval, RecordingValue)] = []
    private var recordingLink: AutoInvalidatingDisplayLink?

    func startRecord() {
        endRecord()

        if !shouldRecord {
            return
        }

        start = CACurrentMediaTime()
        recordingValues = []
        recordingLink = AutoInvalidatingDisplayLink()

        guard let view = view else {
            NSLog("Warning the `view` property is not set")
            return
        }

        recordingValues.append((0.0, recording(view)))

        recordingLink!.callback = { [weak self] _ in
            self?.recordCurrentValue()
        }
    }

    func endRecord() {
        if recordingLink != nil {
            recordingLink = nil

            recordSubject.send(recordingValues)

            recordingValues = []
        } else {
            // Not recording, do nothing
        }
    }

    private func recordCurrentValue() {
        guard let view = view else {
            NSLog("Warning the `view` property is not set")
            return
        }

        guard let recordingLink = recordingLink else {
            NSLog("recordingLink` is invalid")
            return
        }

        let now = recordingLink.link.timestamp
        let value = recording(view)

        recordingValues.append((now - start, value))
    }
}

class UIAnimationController<RecordingValue> {
    var recorder: PropertyRecorder<RecordingValue>?

    private var offset: Bool
    fileprivate var view: UIKitAnimationView? {
        didSet {
            // A little hack, this way when calculating the subview position, we don't need the height of this view
            view?.transform = CGAffineTransform(scaleX: 1, y: -1)
            view?.square.transform = CGAffineTransform(scaleX: 1, y: -1)
            setOffset(offset, animator: nil)
        }
    }

    init(recorder: PropertyRecorder<RecordingValue>?, offset: Bool) {
        self.recorder = recorder
        self.offset = offset
    }

    func setOffset(_ newOffset: Bool, animator: EitherThree<SpringParameter.UIKitSpring, SpringParameter.CASpring, SpringCurve>?) {
        offset = newOffset

        guard let view = view else { return }

        if let animator = animator {
            switch animator {
            case .left(let uiValue):
                UIView.animate(withDuration: uiValue.duration,
                               delay: 0,
                               usingSpringWithDamping: CGFloat(uiValue.dampingRatio),
                               initialSpringVelocity: CGFloat(uiValue.initialVelocity),
                               options: []) { [self] () in
                    view.square.frame = CGRect(x: 0, y: offset ? 100 : 0, width: 100, height: 100)
                }

                let caAnimation = view.square.layer.animation(forKey: "position") as! CASpringAnimation

                let response = 2 * CGFloat.pi / sqrt(caAnimation.stiffness / caAnimation.mass)
                let dampingRatio = caAnimation.damping / 2 / sqrt(caAnimation.stiffness * caAnimation.mass)

                print("Response \(response), damping ratio: \(dampingRatio)")
            case .mid(let caValue):
                let animation = CASpringAnimation()

                animation.mass = CGFloat(caValue.mass)
                animation.stiffness = CGFloat(caValue.stiffness)
                animation.damping = CGFloat(caValue.damping)
                animation.initialVelocity = CGFloat(caValue.initialVelocity)

                animation.keyPath = #keyPath(CALayer.position)
                animation.duration = animation.settlingDuration

                let layer = view.square.layer
                animation.fromValue = (layer.presentation() ?? layer).position

                let newPosition = CGPoint(x: 50, y: offset ? 150 : 50)
                animation.toValue = newPosition

                view.square.layer.add(animation, forKey: "spring")

                view.square.layer.position = newPosition

                print("Settling duration: \(animation.settlingDuration)")
            case .right(let curveValue):
                let animation = CAKeyframeAnimation()

                let keyTimes: [Double] = Array(stride(from: 0.0, to: curveValue.settlingDuration, by: 1 / Double(UIScreen.main.maximumFramesPerSecond)))
                animation.keyTimes = keyTimes
                    .map { time -> Double in
                        let normalTime = time / curveValue.settlingDuration
                        return normalTime
                    } as [NSNumber]

                let layer = view.square.layer
                let fromY = (layer.presentation() ?? layer).position.y
                let toY: CGFloat = offset ? 150 : 50

                animation.values = keyTimes
                    .map(curveValue.curveFunc)
                    .map { normalValue in
                        let y = fromY + CGFloat(normalValue) * (toY - fromY)
                        return CGPoint(x: 50, y: y)
                    }

                animation.keyPath = #keyPath(CALayer.position)
                animation.duration = curveValue.settlingDuration

                view.square.layer.add(animation, forKey: "keyFrameSpring")

                view.square.layer.position = CGPoint(x: 50, y: toY)

                print("Custom settling duration: \(curveValue.settlingDuration)")
            }
        } else {
            view.square.layer.removeAllAnimations()

            view.square.frame = CGRect(x: 0, y: offset ? 100 : 0, width: 100, height: 100)
        }
    }
}

enum AnimationViewType {
    case systemAnimation
    case customAnimation
}

struct UIAnimationView<RecordingValue>: UIViewRepresentable {
    var controller: UIAnimationController<RecordingValue>
    var type: AnimationViewType

    func makeUIView(context: Context) -> UIKitAnimationView {
        let view = UIKitAnimationView()
        controller.recorder?.view = view.square
        controller.view = view
        return view
    }

    func updateUIView(_ uiView: UIKitAnimationView, context: Context) {
        switch type {
        case .systemAnimation:
            uiView.square.backgroundColor = #colorLiteral(red: 0.995510757, green: 0.4321444035, blue: 0, alpha: 1)
            uiView.label.text = "UIKit"
        case .customAnimation:
            uiView.square.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            uiView.label.text = "Custom"
        }
    }
}

class UIKitAnimationView: UIView {
    var square: UIView!
    var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        square = UIView()

        addSubview(square)

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        square.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: square.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: square.centerYAnchor),
        ])
    }
}
