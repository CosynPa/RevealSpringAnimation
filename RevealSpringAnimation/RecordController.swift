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

struct RecordControllerVM {
    @Binding var state: RecordingState

    @Binding var parameter: SpringParameter
    @Binding var recordDuration: Double
    @Binding var offset: Bool

    var recorders: Recorders

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

    func onShouldRecordChange(_ newShouldRecord: Bool) {
        recorders.recorder.shouldRecord = newShouldRecord
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
        recorders.recorder.startRecord()
        recorders.customRecorder.startRecord()

        do {
            switch parameter.type {
            case .spring:
                withAnimation(try parameter.animation()) {
                    offset.toggle()
                }

                // synchronize
                recorders.uikitController.setOffset(offset, animator: nil)

                recorders.customController.setOffset(offset, animator: .right(SpringCurve(parameter.springValue)))
            case .interpolatingSpring:
                withAnimation(try parameter.animation()) {
                    offset.toggle()
                }

                // synchronize
                recorders.uikitController.setOffset(offset, animator: nil)

                recorders.customController.setOffset(offset, animator: .right(SpringCurve(parameter.interpolatingSpringValue)))

            case .uikit:
                offset.toggle()
                recorders.uikitController.setOffset(offset, animator: .left(parameter.uikitValue))
                recorders.customController.setOffset(offset, animator: .right(SpringCurve(parameter.uikitValue)))
            case .coreAnimation:
                offset.toggle()
                recorders.uikitController.setOffset(offset, animator: .mid(parameter.caValue))
                recorders.customController.setOffset(offset, animator: .right(SpringCurve(parameter.caValue)))
            }
        } catch let error as SpringParameter.TypeMissmatchError {
            print("Error:")
            print(error.message)
        } catch {

        }

        return Just(()).delay(for: .seconds(recordDuration), scheduler: DispatchQueue.main)
            .sink { () in
                onStopTime()
            }
    }

    private func handleStop() {
        recorders.recorder.endRecord()
        recorders.customRecorder.endRecord()
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

        recorders.uikitController.setOffset(newOffset, animator: nil)
        recorders.customController.setOffset(newOffset, animator: nil)
    }

}

struct RecordController: View {
    @State var state = RecordingState.notRecording

    @State var shouldRecord = true

    @State var parameter = SpringParameter()
    @State var recordDuration = 2.0
    @State var offset = false

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
            RecordCompareView(recorders: recorders, type: $parameter.type, offset: $offset)
                .padding()

            ZStack(alignment: .top) {
                Color.clear
                VStack {
                    SpringParameterController(parameter: $parameter)
                        .onChange(of: parameter.type) { _ in
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

                    Button("Animate") {
                        vm.onStart()
                    }

                    Button("Reset") {
                        vm.onReset()
                    }
                }
            }
            .padding()
        }
        .onReceive(recorders.recorder.record) { record in
            print(record)
        }
        .onReceive(recorders.customRecorder.record) { record in
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
