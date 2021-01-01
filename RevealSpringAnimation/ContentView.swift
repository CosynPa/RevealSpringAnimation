//
//  ContentView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var recorder = PropertyRecorder<CGFloat> { (view) -> CGFloat in
        let layer = view.layer.presentation()!
        return layer.convert(CGPoint.zero, to: nil).x
    }

    @State var parameter = SpringParameter()
    @State var offset = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            VStack {
                SpringParameterController(parameter: $parameter)

                Divider()

                Button("Animate") {
                    recorder.startRecord()
                    withAnimation(parameter.animation) {
                        offset.toggle()
                    }
                }

                Button("Stop Record") {
                    recorder.endRecord()
                }

                PropertyRecordView<CGFloat>(recorder: recorder)
                    .frame(width: 100, height: 100)
                    .background(Color.yellow)
                    .offset(x: offset ? 100 : 0)
                    .onReceive(recorder.$record) { record in
                        print(record)
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
