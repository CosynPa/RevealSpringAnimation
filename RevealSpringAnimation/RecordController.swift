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

class RecordControllerVM: ObservableObject {
    // Used for system animation
    let recorder: PropertyRecorder<CGFloat>
    let uikitController: UIAnimationController<CGFloat>

    // Used for custom key frame animation
    let customRecorder: PropertyRecorder<CGFloat>
    let customController: UIAnimationController<CGFloat>

    init() {
        recorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
            guard let layer = view.layer.presentation() else {
                // Can happen when the view is off screen
                return 0
            }
            return layer.convert(CGPoint.zero, to: nil).y
        }

        uikitController = UIAnimationController(recorder: recorder, offset: false)

        customRecorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
            guard let layer = view.layer.presentation() else {
                // Can happen when the view is off screen
                return 0
            }
            return layer.convert(CGPoint.zero, to: nil).y
        }
        customRecorder.shouldRecord = false
        customController = UIAnimationController(recorder: customRecorder, offset: false)
    }
}

struct RecordController: View {
    @State var state = RecordingState.notRecording

    @State var shouldRecord = true

    @State var parameter = SpringParameter()
    @State var recordDuration = 2.0
    @State var offset = false

    @StateObject var vm = RecordControllerVM()

    func onStart() {
        let newState: RecordingState

        switch state {
        case .recording(let cancellable):
            cancellable.cancel()
            handleStop()
            fallthrough
        case .notRecording:
            let newCancellable = handleStart()
            newState = .recording(newCancellable)
        }

        state = newState
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

    private func handleStart() -> AnyCancellable {
        vm.recorder.startRecord()
        vm.customRecorder.startRecord()

        do {
            switch parameter.type {
            case .spring, .interpolatingSpring:
                withAnimation(try parameter.animation()) {
                    offset.toggle()
                }

                // synchronize
                vm.uikitController.setOffset(offset, animator: nil)
                // TODO: ainmator
                vm.customController.setOffset(offset, animator: nil)
            case .uikit:
                offset.toggle()
                vm.uikitController.setOffset(offset, animator: .left(try parameter.uikitAnimator()))
                vm.customController.setOffset(offset, animator: .left(try parameter.uikitAnimator())) // TODO: animator
            case .coreAnimation:
                offset.toggle()
                vm.uikitController.setOffset(offset, animator: .right(try parameter.caAnimation()))
                vm.customController.setOffset(offset, animator: .right(try parameter.caAnimation())) // TODO: animator
            }
        } catch let error as SpringParameter.TypeMissmatchError {
            print("Error:")
            print(error.message)
        } catch {

        }

        return Just(()).delay(for: .seconds(recordDuration), scheduler: RunLoop.main)
            .sink { () in
                onStopTime()
            }
    }

    private func handleStop() {
        vm.recorder.endRecord()
        vm.customRecorder.endRecord()
    }

    private func handleReset() {
        stopAnimation(newOffset: false)
    }

    private func handleSwitchType() {
        stopAnimation(newOffset: offset)
    }

    private func stopAnimation(newOffset: Bool) {
        // A hack. Any existing animation will be overriden by setting the offset to a different value first and then setting back
        offset = !newOffset
        withAnimation(.linear(duration: 0)) {
            offset = newOffset
        }

        vm.uikitController.setOffset(newOffset, animator: nil)
        vm.customController.setOffset(newOffset, animator: nil)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RecordCompareView(vm: vm, type: $parameter.type, offset: $offset)
                .padding()

            ZStack(alignment: .top) {
                Color.clear
                VStack {
                    SpringParameterController(parameter: $parameter)
                        .onChange(of: parameter.type) { _ in
                            onSwitchType()
                        }

                    Divider()

                    Toggle("Record", isOn: $shouldRecord)
                        .onChange(of: shouldRecord) { value in
                            vm.recorder.shouldRecord = shouldRecord
                        }

                    HStack {
                        Text("Record Duration")
                        Text(String(format: "%.1f", recordDuration))
                            .frame(width: 60, alignment: .trailing)
                        Slider(value: $recordDuration, in: 0.1 ... 10.0)
                    }

                    Divider()

                    Button("Animate") {
                        onStart()
                    }

                    Button("Reset") {
                        onReset()
                    }
                }
            }
            .padding()
        }
        .onReceive(vm.recorder.record) { record in
            print(record)
        }
        .onReceive(vm.customRecorder.record) { record in
            print("Custom animation record")
            print(record)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RecordController()
    }
}
