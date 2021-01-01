//
//  SpringParameterController.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/31.
//

import SwiftUI

struct SpringParameter {
    enum SpringType: Hashable {
        case spring
        case interpolatingSpring
    }

    var type = SpringType.spring

    var response: Double = 0.55
    var dampingFraction: Double = 0.825
    var blendDuration: Double = 0

    var mass: Double = 1.0
    var stiffness: Double = 1.0
    var damping: Double = 1.0
    var initialVelocity: Double = 0.0

    var animation: Animation {
        switch type {
        case .spring:
            return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        case .interpolatingSpring:
            return .interpolatingSpring(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)
        }
    }
}

struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? {
        nil
    }

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {

    }
}

struct SpringParameterController: View {
    @Binding var parameter: SpringParameter

    @State var textWidth: CGFloat = 100

    var columns: [GridItem] {
        [
            GridItem(.fixed(textWidth), alignment: .leading),
            GridItem(.fixed(60), alignment: .trailing),
            GridItem(.flexible())
        ]
    }

    var parameterSettings: [(String, ClosedRange<Double>, Binding<Double>)] {
        if case .spring = parameter.type {
            return [
                ("Response", 0.01 ... 2.00, $parameter.response),
                ("Damping Fraction", 0.0 ... 2.0, $parameter.dampingFraction),
                ("Blend Duration", 0.0 ... 2.0, $parameter.blendDuration)
            ]
        } else {
            return [
                ("Mass", 0.1 ... 2.0, $parameter.mass),
                ("Stiffness", 0.1 ... 5.0, $parameter.stiffness),
                ("Damping", 0.01 ... 5.0, $parameter.damping),
                ("Initial Velocity", -5.0 ... 5.0, $parameter.initialVelocity)
            ]
        }
    }

    // This view is used to get the maximum text width, the value is set to `textWidth`
    @ViewBuilder
    var textWidthView: some View {
        VStack {
            ForEach(parameterSettings, id: \.0) { (item) in
                Text(item.0)
            }
        }
        .background(GeometryReader { proxy in
            Color.clear
                .preference(key: TextWidthKey.self, value: proxy.size.width)
                .onPreferenceChange(TextWidthKey.self) { value in
                    if let value = value {
                        textWidth = value
                    }
                }
        })
        .hidden()
    }

    var body: some View {
        VStack {
            Picker("Type", selection: $parameter.type) {
                Text("Spring")
                    .tag(SpringParameter.SpringType.spring)
                Text("Interpolating Spring")
                    .tag(SpringParameter.SpringType.interpolatingSpring)
            }
            .pickerStyle(SegmentedPickerStyle())

            LazyVGrid(columns: columns) {
                ForEach(parameterSettings, id: \.0) { setting in
                    let (title, range, property) = setting
                    Text(title)
                    Text(String(format: "%.2f", property.wrappedValue))
                    Slider(value: property, in: range)
                }
            }
        }
        .background(textWidthView)
        .padding()
    }
}

struct SpringParameterController_Previews: PreviewProvider {
    struct Wrapper: View {
        @State var parameter = SpringParameter()

        var body: some View {
            SpringParameterController(parameter: $parameter)
        }
    }

    static var previews: some View {
        Wrapper()
    }
}
