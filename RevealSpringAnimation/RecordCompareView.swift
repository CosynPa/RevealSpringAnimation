//
//  RecordCompareView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/10.
//

import SwiftUI

struct RecordCompareView: View {
    var recorders: Recorders

    @Binding var type: SpringType
    @Binding var offset: Bool

    @ViewBuilder
    var systemView: some View {
        switch type {
        case .spring, .interpolatingSpring:
            VStack {
                Spacer()
                ZStack {
                    PropertyRecordView<CGFloat>(recorder: recorders.recorder)
                        .background(Color.yellow)
                    Text("SwiftUI")
                }
                .frame(width: 100, height: 100)
                .offset(y: offset ? -100 : 0)
            }
            .frame(width: 100)
        case .uikit, .coreAnimation:
            UIAnimationView(controller: recorders.uikitController, type: .systemAnimation)
                .onAppear {
                    recorders.uikitController.setOffset(offset, animator: nil)
                }
                .frame(width: 100)
        }
    }

    @ViewBuilder
    var compareView: some View {
        UIAnimationView(controller: recorders.customController, type: .customAnimation)
            .onAppear {
                recorders.customController.setOffset(offset, animator: nil)
            }
            .frame(width: 100)
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            systemView
            compareView
            Spacer()
        }
    }
}

struct RecordCompareView_Previews: PreviewProvider {
    static var vm = Recorders()

    static var previews: some View {
        Group {
            RecordCompareView(recorders: vm, type: .constant(.spring), offset: .constant(false))

            RecordCompareView(recorders: vm, type: .constant(.spring), offset: .constant(true))

            RecordCompareView(recorders: vm, type: .constant(.uikit), offset: .constant(false))

            RecordCompareView(recorders: vm, type: .constant(.uikit), offset: .constant(true))

        }
        .previewLayout(.fixed(width: 400, height: 250))
    }
}
