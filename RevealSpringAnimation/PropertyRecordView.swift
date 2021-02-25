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

        recorder.recordTargetView = view

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

    // Provided by PropertyRecordView or UIAnimationView, the user should not directly set this property
    fileprivate var recordTargetView: UIView?

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

        guard let view = recordTargetView else {
            NSLog("Warning the `recordTargetView` property is not set")
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
        guard let view = recordTargetView else {
            NSLog("Warning the `view` property is not set")
            return
        }

        guard let recordingLink = recordingLink else {
            NSLog("recordingLink` is invalid")
            return
        }

        let now = recordingLink.link.timestamp
        let value = recording(view)

        if now - start > 0 { // Maybe negative since timestamp is the last frame
            recordingValues.append((now - start, value))
        }
    }
}

class UIAnimationController<RecordingValue> {
    var recorder: PropertyRecorder<RecordingValue>?

    enum Animator {
        // mimic: If true, use key frame animation to mimic the system animation; if false, directly use system API.
        case uikit(UIKitSpring, mimic: Bool)
        case coreAnimation(CASpring, mimic: Bool)
        case keyboard(mimic: Bool)

        // Always mimic here, calling SwiftUI system animation is in RecordControllerVM
        case spring(Spring)
        case interpolatingSpring(InterpolatingSpring)
    }

    enum MixStrategy {
        case noMix
        case compose
        case keepVelocity
    }

    var previous: (function: MotionFunction, startTime: CFTimeInterval)?

    fileprivate var view: UIKitAnimationView? {
        didSet {
            // A little hack, this way when calculating the subview position, we don't need the height of this view
            view?.transform = CGAffineTransform(scaleX: 1, y: -1)
            view?.shapeView.transform = CGAffineTransform(scaleX: 1, y: -1)
            set(offset: 0, animator: nil)
        }
    }

    init(recorder: PropertyRecorder<RecordingValue>?, offset: Bool) {
        self.recorder = recorder
    }

    func set(offset: CGFloat, animator: Animator?) {
        guard let view = view else { return }

        if let animator = animator {
            switch animator {
            case .uikit(let uiValue, let shouldMimic):
                if shouldMimic {
                    previous = mimic(curve: SpringCurve(uiValue), offset: offset, mixStrategy: .noMix)
                } else {
                    UIView.animate(withDuration: uiValue.duration,
                                   delay: 0,
                                   usingSpringWithDamping: CGFloat(uiValue.dampingRatio),
                                   initialSpringVelocity: CGFloat(uiValue.initialVelocity),
                                   options: []) { () in
                        view.shapeView.frame = CGRect(x: 0, y: -offset, width: 100, height: 100)
                    }

                    let caAnimation = view.shapeView.layer.animation(forKey: "position") as! CASpringAnimation

                    let response = 2 * CGFloat.pi / sqrt(caAnimation.stiffness / caAnimation.mass)
                    let dampingRatio = caAnimation.damping / 2 / sqrt(caAnimation.stiffness * caAnimation.mass)

                    print("Response \(response), damping ratio: \(dampingRatio), settling duration: \(caAnimation.settlingDuration)")

                    // No mix with system animation
                    previous = nil
                }
            case .coreAnimation(let caValue, let shouldMimic):
                if shouldMimic {
                    previous = mimic(curve: SpringCurve(caValue), offset: offset, mixStrategy: .noMix)
                } else {
                    let animation = CASpringAnimation()

                    animation.mass = CGFloat(caValue.mass)
                    animation.stiffness = CGFloat(caValue.stiffness)
                    animation.damping = CGFloat(caValue.damping)
                    animation.initialVelocity = CGFloat(caValue.initialVelocity)

                    animation.keyPath = #keyPath(CALayer.position)
                    animation.duration = animation.settlingDuration

                    let layer = view.shapeView.layer
                    animation.fromValue = (layer.presentation() ?? layer).position

                    let newPosition = CGPoint(x: 50, y: 50 - offset)
                    animation.toValue = newPosition

                    view.shapeView.layer.add(animation, forKey: "spring")

                    view.shapeView.layer.position = newPosition

                    print("Settling duration: \(animation.settlingDuration)")

                    // No mix with system animation
                    previous = nil
                }
            case .spring(let springValue):
                previous = mimic(curve: SpringCurve(springValue), offset: offset, mixStrategy: .keepVelocity)
            case .interpolatingSpring(let interpolatingSpringValue):
                previous = mimic(curve: SpringCurve(interpolatingSpringValue), offset: offset, mixStrategy: .compose)
            case .keyboard(let shouldMimic):
                if shouldMimic {
                    // If directly set animation when receive keyboard notifications,
                    // the animation will be mixed with system keyboard animation, so dispatch async to
                    // avoid this behavior
                    DispatchQueue.main.async { [self] () in
                        previous = mimic(curve: SpringCurve.makeKeyboardSpring(), offset: offset, mixStrategy: .noMix)
                    }
                } else {
                    // If set frame when receive keyboard will show or hide notifications
                    // it will be automatically animated
                    view.shapeView.layer.removeAllAnimations()
                    view.shapeView.frame = CGRect(x: 0, y: -offset, width: 100, height: 100)
                    previous = nil
                }
            }
        } else {
            view.shapeView.layer.removeAllAnimations()
            view.shapeView.frame = CGRect(x: 0, y: -offset, width: 100, height: 100)
            previous = nil
        }
    }

    func mimic(curve: SpringCurve, offset: CGFloat, mixStrategy: MixStrategy) -> (function: MotionFunction, startTime: CFTimeInterval)? {
        guard let view = view else { return nil }

        let animation = CAKeyframeAnimation()

        let layer = view.shapeView.layer
        let fromY = (layer.presentation() ?? layer).position.y
        let toY: CGFloat = 50 - offset

        let function: MotionFunction
        if let previous = previous {
            let startTimeOffset = CACurrentMediaTime() - previous.startTime
            print("Start offset \(startTimeOffset)")
            if let animation = view.shapeView.layer.animation(forKey: "keyFrameSpring") as? CAKeyframeAnimation,
               startTimeOffset <= animation.duration {
                switch mixStrategy {
                case .noMix:
                    function = SimpleCurve(curve: curve, from: fromY, to: toY)
                case .compose:
                    function = ComposedCurve(previous: previous.function, startOffset: startTimeOffset,
                                             curve: curve, to: toY)
                case .keepVelocity:
                    function = KeepVelocityCurve(previous: previous.function, startOffset: startTimeOffset,
                                                 curve: curve, to: toY)
                }
            } else {
                function = SimpleCurve(curve: curve, from: fromY, to: toY)
            }
        } else {
            function = SimpleCurve(curve: curve, from: fromY, to: toY)
        }

        let settlingDuration = min(function.settlingDuration, 3600)

        let keyTimes: [Double] = Array(stride(from: 0.0, to: settlingDuration, by: 1 / Double(UIScreen.main.maximumFramesPerSecond)))
        animation.keyTimes = keyTimes
            .map { time -> Double in
                let normalTime = time / settlingDuration
                return normalTime
            } as [NSNumber]

        animation.values = keyTimes
            .map { t in
                CGPoint(x: 50, y: function.value(at: t))
            }

        animation.keyPath = #keyPath(CALayer.position)
        animation.duration = settlingDuration

        view.shapeView.layer.add(animation, forKey: "keyFrameSpring")

        view.shapeView.layer.position = CGPoint(x: 50, y: toY)

        print("Mimic settling duration: \(settlingDuration)")

        return (function, CACurrentMediaTime())
    }
}

enum AnimationViewType {
    case systemAnimation
    case mimicAnimation
}

struct UIAnimationView<RecordingValue>: UIViewRepresentable {
    var controller: UIAnimationController<RecordingValue>
    var type: AnimationViewType

    func makeUIView(context: Context) -> UIKitAnimationView {
        let view = UIKitAnimationView()
        controller.recorder?.recordTargetView = view.shapeView
        controller.view = view
        return view
    }

    func updateUIView(_ uiView: UIKitAnimationView, context: Context) {
        switch type {
        case .systemAnimation:
            uiView.shapeView.backgroundColor = #colorLiteral(red: 0.995510757, green: 0.4321444035, blue: 0, alpha: 1)
            uiView.label.text = "UIKit"
        case .mimicAnimation:
            uiView.shapeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            uiView.label.text = "Mimic"
        }
    }
}

class UIKitAnimationView: UIView {
    var shapeView: UIView!
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
        shapeView = UIView()

        addSubview(shapeView)

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        shapeView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: shapeView.centerYAnchor),
        ])
    }
}
