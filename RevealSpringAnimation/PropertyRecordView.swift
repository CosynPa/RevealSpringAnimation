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
    var recordInterval: TimeInterval
    var tolerance: TimeInterval

    // When calls this function, it should return the current value that you want to record
    var recording: (UIView) -> RecordingValue

    @Published var record: [(TimeInterval, RecordingValue)] = []

    // Provided by PropertyRecordView, the user should not directly set this property
    fileprivate var view: UIView?

    private let endSubject = PassthroughSubject<Void, Never>()

    init(recordInterval: TimeInterval = 0.001, tolerance: TimeInterval = 0.0005, recording: @escaping (UIView) -> RecordingValue) {
        self.recordInterval = recordInterval
        self.tolerance = tolerance
        self.recording = recording
    }

    func startRecord() {
        let start = CACurrentMediaTime()

        Timer.publish(every: recordInterval, tolerance: tolerance, on: .main, in: .default)
            .autoconnect()
            .map { _ in CACurrentMediaTime() - start }
            .prepend(0.0)
            .prefix(untilOutputFrom: endSubject)
            .compactMap { [weak self] (time) -> (CFTimeInterval, RecordingValue)? in
                if let self = self, let view = self.view {
                    return (time, self.recording(view))
                } else {
                    return nil
                }
            }
            .collect()
            .assign(to: &$record)
    }

    func endRecord() {
        endSubject.send()
    }
}
