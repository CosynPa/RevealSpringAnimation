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

class PropertyRecorder<RecordingValue>: ObservableObject {
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
            view?.offset.constant = offset ? 100 : 0
        }
    }

    init(recorder: PropertyRecorder<RecordingValue>?, offset: Bool) {
        self.recorder = recorder
        self.offset = offset
    }

    func setOffset(_ newOffset: Bool, animator: UIViewPropertyAnimator?) {
        offset = newOffset

        guard let view = view else { return }

        if let animator = animator {
            animator.addAnimations { [self] () in
                view.offset.constant = offset ? 100 : 0
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
            animator.startAnimation()
        } else {
            view.offset.constant = offset ? 100 : 0
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
    var offset: NSLayoutConstraint!
    var square: UIView!

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
        square.translatesAutoresizingMaskIntoConstraints = false
        square.backgroundColor = #colorLiteral(red: 0.9960784314, green: 0.7607843137, blue: 0.03921568627, alpha: 1)

        addSubview(square)

        offset = square.leadingAnchor.constraint(equalTo: leadingAnchor)

        NSLayoutConstraint.activate([
            square.widthAnchor.constraint(equalToConstant: 100),
            square.heightAnchor.constraint(equalToConstant: 100),
            offset
        ])
    }
}