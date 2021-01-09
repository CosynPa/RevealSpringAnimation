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
    // When calls this function, it should return the current value that you want to record
    var recording: (UIView) -> RecordingValue

    @Published var record: [(TimeInterval, RecordingValue)] = []

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

            record = recordingValues

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
            setOffset(offset, animator: nil)
        }
    }

    init(recorder: PropertyRecorder<RecordingValue>?, offset: Bool) {
        self.recorder = recorder
        self.offset = offset
    }

    func setOffset(_ newOffset: Bool, animator: Either<UIViewPropertyAnimator, CASpringAnimation>?) {
        offset = newOffset

        guard let view = view else { return }

        if let animator = animator {
            switch animator {
            case .left(let uikitAnimator):
                view.animator?.stopAnimation(false)
                view.animator = nil

                uikitAnimator.addAnimations { [self] () in
                    view.square.frame = CGRect(x: offset ? 100 : 0, y: 0, width: 100, height: 100)
                }
                uikitAnimator.startAnimation()

                view.animator = uikitAnimator
            case .right(let caAnimator):
                caAnimator.keyPath = #keyPath(CALayer.position)

                caAnimator.fromValue = view.square.layer.position

                let newPosition = CGPoint(x: offset ? 150 : 50, y: 50)
                caAnimator.toValue = newPosition

                view.square.layer.add(caAnimator, forKey: "spring")

                view.square.layer.position = newPosition
            }
        } else {
            view.animator?.stopAnimation(false)
            view.animator = nil

            view.square.layer.removeAnimation(forKey: "spring")
            view.square.frame = CGRect(x: offset ? 100 : 0, y: 0, width: 100, height: 100)
        }
    }
}

struct UIAnimationView<RecordingValue>: UIViewRepresentable {
    var controller: UIAnimationController<RecordingValue>

    func makeUIView(context: Context) -> UIKitAnimationView {
        let view = UIKitAnimationView()
        controller.recorder?.view = view.square
        controller.view = view
        return view
    }

    func updateUIView(_ uiView: UIKitAnimationView, context: Context) {

    }
}

class UIKitAnimationView: UIView {
    var square: UIView!
    var animator: UIViewPropertyAnimator?

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
        square.backgroundColor = #colorLiteral(red: 0.9960784314, green: 0.7607843137, blue: 0.03921568627, alpha: 1)

        addSubview(square)
    }
}
