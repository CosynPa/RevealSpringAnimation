//
//  ContentView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/20.
//

import SwiftUI
import Combine

enum RecordingState {
    case recording(UUID)
    case idle
}

class RecordControllerVM: ObservableObject {
    let recorder: PropertyRecorder<CGFloat>
    let uikitController: UIAnimationController<CGFloat>

    init() {
        recorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
            guard let layer = view.layer.presentation() else {
                // Can happen when the view is off screen
                return 0
            }
            return layer.convert(CGPoint.zero, to: nil).x
        }

        uikitController = UIAnimationController(recorder: recorder, offset: false)
    }
}

struct RecordController: View {
    @State var state = RecordingState.idle

    @State var parameter = SpringParameter()
    @State var recordDuration = 2.0
    @State var offset = false

    @StateObject var vm = RecordControllerVM()

    func onStart() {
        let newState: RecordingState

        switch state {
        case .recording:
            handleStop()
            fallthrough
        case .idle:
            let id = UUID()
            newState = .recording(id)
            handleStart(id)
        }

        state = newState
    }

    func onReset() {
        let newState: RecordingState

        switch state {
        case .recording:
            handleStop()
            fallthrough
        case .idle:
            newState = .idle
            handleReset()
        }

        state = newState
    }

    private func onStopTime(_ id: UUID) {
        let newState: RecordingState

        switch state {
        case .idle:
            newState = .idle
        case .recording(let currentID):
            if currentID == id {
                handleStop()
                newState = .idle
            } else {
                // Should already be stopped, reject
                newState = state
            }
        }

        state = newState
    }

    private func handleStart(_ id: UUID) {
        vm.recorder.startRecord()

        do {
            switch parameter.type {
            case .spring, .interpolatingSpring:
                withAnimation(try parameter.animation()) {
                    offset.toggle()
                    // synchronize
                    vm.uikitController.setOffset(offset, animator: nil)
                }
            case .uikit:
                offset.toggle()
                vm.uikitController.setOffset(offset, animator: .left(try parameter.uikitAnimator()))
            case .coreAnimation:
                offset.toggle()
                vm.uikitController.setOffset(offset, animator: .right(try parameter.caAnimation()))
            }
        } catch let error as SpringParameter.TypeMissmatchError {
            print("Error:")
            print(error.message)
        } catch {

        }

        DispatchQueue.main.asyncAfter(deadline: .now() + recordDuration) { () in
            onStopTime(id)
        }
    }

    private func handleStop() {
        vm.recorder.endRecord()
    }

    private func handleReset() {
        offset = false
        vm.uikitController.setOffset(offset, animator: nil)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            VStack {
                SpringParameterController(parameter: $parameter)

                Divider()

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

                switch parameter.type {
                case .spring, .interpolatingSpring:
                    HStack {
                        PropertyRecordView<CGFloat>(recorder: vm.recorder)
                            .frame(width: 100, height: 100)
                            .background(Color.yellow)
                            .offset(x: offset ? 100 : 0)
                        Spacer()
                    }
                case .uikit, .coreAnimation:
                    UIAnimationView(controller: vm.uikitController)
                        .frame(height: 100)
                }
            }
            .padding()
            .onReceive(vm.recorder.$record) { record in
                print(record)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RecordController()
    }
}
