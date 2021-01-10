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

    var body: some View {
        switch type {
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
                .onAppear {
                    vm.uikitController.setOffset(offset, animator: nil)
                }
                .frame(height: 100)
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
        .previewLayout(.sizeThatFits)
    }
}
