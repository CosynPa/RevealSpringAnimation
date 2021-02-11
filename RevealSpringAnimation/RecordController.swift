//
//  ContentView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/20.
//

import SwiftUI
import Combine

enum RecordingState {
    case recording(AnyCancellable)
    case notRecording  // Not this doesn't necessarily mean not animating
}

class Recorders: ObservableObject {
    // Used for system animation
    let recorder: PropertyRecorder<CGFloat>
    let uikitController: UIAnimationController<CGFloat>

    // Used for custom key frame animation
    let mimicRecorder: PropertyRecorder<CGFloat>
    let mimicController: UIAnimationController<CGFloat>

    private var bag = Set<AnyCancellable>()

    init() {
        recorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
            guard let layer = view.layer.presentation() else {
                // Can happen when the view is off screen
                return 0
            }
            return layer.convert(CGPoint.zero, to: nil).y
        }

        recorder.record.sink { (record) in
            RecordCollector.shared.systemAnimationRecord = record
        }.store(in: &bag)

        uikitController = UIAnimationController(recorder: recorder, offset: false)

        mimicRecorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
            guard let layer = view.layer.presentation() else {
                // Can happen when the view is off screen
                return 0
            }
            return layer.convert(CGPoint.zero, to: nil).y
        }

        mimicRecorder.record.sink { (record) in
            RecordCollector.shared.mimicAnimationRecord = record
        }.store(in: &bag)

        mimicController = UIAnimationController(recorder: mimicRecorder, offset: false)
    }
}

struct RecordControllerVM {
    @Binding var state: RecordingState

    @MultiSpringParameterEdit var parameter: MultiSpringParameter
    @Binding var recordDuration: Double
    @Binding var offset: CGFloat

    var recorders: Recorders

    private func transitToStart(newOffset: CGFloat) {
        let newState: RecordingState

        switch state {
        case .recording(let cancellable):
            cancellable.cancel()
            handleStop()
            fallthrough
        case .notRecording:
            let newCancellable = handleStart(newOffset: newOffset)
            newState = .recording(newCancellable)
        }

        state = newState
    }

    func onStart() {
        transitToStart(newOffset: offset == 0 ? -100 : 0)
    }

    func onReset() {
        let newState: RecordingState

        switch state {
        case .recording(let cancellable):
            cancellable.cancel()
            handleStop()
            fallthrough
        case .notRecording:
            newState = .notRecording
            handleReset()
        }

        state = newState
    }

    func onKeyboardShowAnimationStart(info: KeyboardInfo) {
        let newOffset = -info.endFrame.height
        if info.animate {
            transitToStart(newOffset: newOffset)
        } else {
            stopAnimation(newOffset: newOffset)
        }
    }

    func onKeyboardHideAnimationStart(info: KeyboardInfo) {
        if info.animate {
            transitToStart(newOffset: 0)
        } else {
            stopAnimation(newOffset: 0)
        }
    }

    // When the user switch to a different parameter type
    func onSwitchType() {
        let newState: RecordingState

        switch state {
        case .recording(let cancellable):
            cancellable.cancel()
            handleStop()
            fallthrough
        case .notRecording:
            newState = .notRecording
            handleSwitchType()
        }

        state = newState
    }

    func onShouldRecordChange(_ newShouldRecord: Bool) {
        RecordCollector.shared.printRecord = newShouldRecord
    }

    private func onStopTime() {
        let newState: RecordingState

        switch state {
        case .notRecording:
            newState = .notRecording
        case .recording:
            // Normal stop, no need to cancel
            handleStop()
            newState = .notRecording
        }

        state = newState
    }

    private func handleStart(newOffset: CGFloat) -> AnyCancellable {
        recorders.recorder.startRecord()
        recorders.mimicRecorder.startRecord()

        switch parameter {
        case .spring(let springValue):
            withAnimation(springValue.animation) {
                offset = newOffset
            }

            // synchronize
            recorders.uikitController.set(offset: offset, animator: nil)

            recorders.mimicController.set(offset: offset,
                                          animator: .spring(springValue))
        case .interpolatingSpring(let interpolatingSpringValue):
            withAnimation(interpolatingSpringValue.animation) {
                offset = newOffset
            }

            // synchronize
            recorders.uikitController.set(offset: offset, animator: nil)

            recorders.mimicController.set(offset: offset,
                                          animator: .interpolatingSpring(interpolatingSpringValue))
        case .uikit(let uikitValue):
            offset = newOffset
            recorders.uikitController.set(offset: offset, animator: .uikit(uikitValue, mimic: false))
            recorders.mimicController.set(offset: offset, animator: .uikit(uikitValue, mimic: true))
        case .coreAnimation(let caValue):
            offset = newOffset
            recorders.uikitController.set(offset: offset, animator: .coreAnimation(caValue, mimic: false))
            recorders.mimicController.set(offset: offset, animator: .coreAnimation(caValue, mimic: true))
        case .keyboard:
            offset = newOffset
            recorders.uikitController.set(offset: offset, animator: .keyboard(mimic: false))
            recorders.mimicController.set(offset: offset,
                                          animator: .keyboard(mimic: true))
        }

        return Just(()).delay(for: .seconds(recordDuration), scheduler: DispatchQueue.main)
            .sink { () in
                onStopTime()
            }
    }

    private func handleStop() {
        recorders.recorder.endRecord()
        recorders.mimicRecorder.endRecord()
    }

    private func handleReset() {
        stopAnimation(newOffset: 0)
    }

    private func handleSwitchType() {
        stopAnimation(newOffset: offset)
    }

    private func stopAnimation(newOffset: CGFloat) {
        // A hack. Any existing animation will be overriden by setting the offset to a different value first and then setting back
        offset = newOffset + 10
        withAnimation(.linear(duration: 0)) {
            offset = newOffset
        }

        recorders.uikitController.set(offset: newOffset, animator: nil)
        recorders.mimicController.set(offset: newOffset, animator: nil)
    }

}

struct RecordController: View {
    @State var state = RecordingState.notRecording

    @State var shouldRecord = true

    @MultiSpringParameterEdit var parameter: MultiSpringParameter
    @State var recordDuration = 2.0
    @State var offset = CGFloat(0)

    @StateObject var recorders = Recorders()

    var vm: RecordControllerVM {
        RecordControllerVM(state: $state,
                           parameter: $parameter,
                           recordDuration: $recordDuration,
                           offset: $offset,
                           recorders: recorders)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RecordCompareView(recorders: recorders, type: $parameter.$type, offset: $offset)
                .padding(.bottom, parameter.isKeyboard ? 0 : 16)
                .ignoresSafeArea(parameter.isKeyboard ? .all : .keyboard, edges: .bottom)

            ZStack(alignment: .top) {
                Color.clear
                VStack {
                    MultiSpringParameterController(editingParameter: $parameter)
                        .onChange(of: $parameter.type) { _ in
                            vm.onSwitchType()
                        }

                    Divider()

                    Toggle("Record", isOn: $shouldRecord)
                        .onChange(of: shouldRecord) { value in
                            vm.onShouldRecordChange(value)
                        }

                    HStack {
                        Text("Record Duration")
                        Text(String(format: "%.1f", recordDuration))
                            .frame(width: 60, alignment: .trailing)
                        Slider(value: $recordDuration, in: 0.1 ... 10.0)
                    }

                    Divider()

                    if parameter.isKeyboard {
                        TextField("Tap here to show the keyboard", text: .constant(""))
                    } else {
                        Button("Animate") {
                            vm.onStart()
                        }

                        Button("Reset") {
                            vm.onReset()
                        }
                    }
                }
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIView.keyboardWillShowNotification)) { notification in
            vm.onKeyboardShowAnimationStart(info: KeyboardInfo(notification: notification))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIView.keyboardWillHideNotification)) { notification in
            vm.onKeyboardHideAnimationStart(info: KeyboardInfo(notification: notification))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RecordController()
    }
}
