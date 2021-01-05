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
        let layer = view.layer.presentation()!
        return layer.convert(CGPoint.zero, to: nil).x
    }

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

        withAnimation(parameter.animation) {
            offset.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + recordDuration) { [weak self] () in
            self?.onStopTime(id)
        }
    }

    private func handleStop() {
        recorder.endRecord()
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

                HStack {
                    PropertyRecordView<CGFloat>(recorder: vm.recorder)
                        .frame(width: 100, height: 100)
                        .background(Color.yellow)
                        .offset(x: vm.offset ? 100 : 0)
                        .onReceive(vm.recorder.$record) { record in
                            print(record)
                        }

                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RecordController()
    }
}
