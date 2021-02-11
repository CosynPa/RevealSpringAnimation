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
    @Binding var offset: CGFloat

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
                .offset(y: offset)
            }
            .frame(width: 100)
        case .uikit, .coreAnimation, .keyboard:
            UIAnimationView(controller: recorders.uikitController, type: .systemAnimation)
                .onAppear {
                    recorders.uikitController.set(offset: offset, animator: nil)
                }
                .frame(width: 100)
        }
    }

    private var mimicAnimationViewType: AnimationViewType {
        switch type {
        case .keyboard:
            return .mimicKeyboardAnimation
        default:
            return .mimicAnimation
        }
    }

    @ViewBuilder
    var compareView: some View {
        UIAnimationView(controller: recorders.mimicController, type: mimicAnimationViewType)
            .onAppear {
                recorders.mimicController.set(offset: offset, animator: nil)
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
            RecordCompareView(recorders: vm, type: .constant(.spring), offset: .constant(0))

            RecordCompareView(recorders: vm, type: .constant(.spring), offset: .constant(100))

            RecordCompareView(recorders: vm, type: .constant(.uikit), offset: .constant(0))

            RecordCompareView(recorders: vm, type: .constant(.uikit), offset: .constant(100))

        }
        .previewLayout(.fixed(width: 400, height: 250))
    }
}
