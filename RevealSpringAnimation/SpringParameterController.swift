//
//  SpringParameterController.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/31.
//

import SwiftUI

enum SpringParameter {
    case spring(response: Double = 0.55, dampingFraction: Double = 0.825, blendDuration: Double = 0)
    case interactiveSpring(response: Double = 0.15, dampingFraction: Double = 0.86, blendDuration: Double = 0.25)
}

struct SpringParameterController: View {
    @Binding var parameter: SpringParameter

    var body: some View {
        VStack {
            Text("a")
        }
    }
}

struct SpringParameterController_Previews: PreviewProvider {
    struct Wrapper: View {
        @State var parameter = SpringParameter.spring()

        var body: some View {
            SpringParameterController(parameter: $parameter)
        }
    }

    static var previews: some View {
        Wrapper()
    }
}
