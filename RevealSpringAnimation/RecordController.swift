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
    var state = RecordingState.idle

    @Published var parameter = SpringParameter()
    @Published var recordDuration = 2.0
    @Published var offset = false

    var recorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
        guard let layer = view.layer.presentation() else {
            // Can happen when the view is off screen
            return 0
        }
        return layer.convert(CGPoint.zero, to: nil).x
    }

    lazy var uikitController: UIAnimationController<CGFloat> = { (self) in
        return UIAnimationController(recorder: self.recorder, offset: self.offset)
    }(self)

    private var bag = Set<AnyCancellable>()

    init() {
        recorder.objectWillChange.sink { [weak self] () in
            self?.objectWillChange.send()
        }
        .store(in: &bag)
    }

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
        recorder.startRecord()

        do {
            switch parameter.type {
            case .spring, .interpolatingSpring:
                withAnimation(try parameter.animation()) {
                    offset.toggle()
                    // synchronize
                    uikitController.setOffset(offset, animator: nil)
                }
            case .uikit:
                try withAnimation {
                    offset.toggle()
                    uikitController.setOffset(offset, animator: try parameter.uikitAnimator())
                }
            }
        } catch let error as SpringParameter.TypeMissmatchError {
            print("Error:")
            print(error.message)
        } catch {

        }

        DispatchQueue.main.asyncAfter(deadline: .now() + recordDuration) { [weak self] () in
            self?.onStopTime(id)
        }
    }

    private func handleStop() {
        recorder.endRecord()
    }

    private func handleReset() {
        offset = false
        uikitController.setOffset(offset, animator: nil)
    }
}

struct RecordController: View {
    @StateObject var vm = RecordControllerVM()

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            VStack {
                SpringParameterController(parameter: $vm.parameter)

                Divider()

                HStack {
                    Text("Record Duration")
                    Text(String(format: "%.1f", vm.recordDuration))
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $vm.recordDuration, in: 0.1 ... 10.0)
                }

                Divider()

                Button("Animate") {
                    vm.onStart()
                }

                Button("Reset") {
                    vm.onReset()
                }

                switch vm.parameter.type {
                case .spring, .interpolatingSpring:
                    HStack {
                        PropertyRecordView<CGFloat>(recorder: vm.recorder)
                            .frame(width: 100, height: 100)
                            .background(Color.yellow)
                            .offset(x: vm.offset ? 100 : 0)
                        Spacer()
                    }
                case .uikit:
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
