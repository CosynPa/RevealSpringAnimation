//
//  RecordCompareView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/1/10.
//

import SwiftUI

struct RecordCompareView: View {
    var vm: RecordControllerVM

    @Binding var type: SpringParameter.SpringType
    @Binding var offset: Bool

    @ViewBuilder
    var systemView: some View {
        switch type {
        case .spring, .interpolatingSpring:
            VStack {
                Spacer()
                PropertyRecordView<CGFloat>(recorder: vm.recorder)
                    .frame(width: 100, height: 100)
                    .background(Color.yellow)
                    .offset(y: offset ? -100 : 0)
            }
            .frame(width: 100)
        case .uikit, .coreAnimation:
            UIAnimationView(controller: vm.uikitController)
                .onAppear {
                    vm.uikitController.setOffset(offset, animator: nil)
                }
                .frame(width: 100)
        }
    }

    @ViewBuilder
    var compareView: some View {
        UIAnimationView(controller: vm.customController)
            .onAppear {
                vm.customController.setOffset(offset, animator: nil)
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
    static var vm = RecordControllerVM()

    static var previews: some View {
        Group {
            RecordCompareView(vm: vm, type: .constant(.spring), offset: .constant(false))

            RecordCompareView(vm: vm, type: .constant(.spring), offset: .constant(true))

            RecordCompareView(vm: vm, type: .constant(.uikit), offset: .constant(false))

            RecordCompareView(vm: vm, type: .constant(.uikit), offset: .constant(true))

        }
        .previewLayout(.fixed(width: 400, height: 250))
    }
}
