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
        case uikit
    }

    struct Spring {
        var response: Double = 0.55
        var dampingFraction: Double = 0.825
        var blendDuration: Double = 0
    }

    struct InterpolatingSpring {
        var mass: Double = 1.0
        var stiffness: Double = 1.0
        var damping: Double = 1.0
        var initialVelocity: Double = 0.0
    }

    struct UIKitSpring {
        var duration: Double = 0.5
        var dampingRatio: Double = 1.0
    }

    struct TypeMissmatchError: Error {
        var message: String
    }

    var type = SpringType.spring

    var springValue = Spring()
    var interpolatingSpringValue = InterpolatingSpring()
    var uikitValue = UIKitSpring()

    func animation() throws -> Animation   {
        switch type {
        case .spring:
            return .spring(
                response: springValue.response,
                dampingFraction: springValue.dampingFraction,
                blendDuration: springValue.blendDuration
            )
        case .interpolatingSpring:
            return .interpolatingSpring(
                mass: interpolatingSpringValue.mass,
                stiffness: interpolatingSpringValue.stiffness,
                damping: interpolatingSpringValue.damping,
                initialVelocity: interpolatingSpringValue.initialVelocity
            )
        case .uikit:
            throw TypeMissmatchError(message: "No animation for uikit type")
        }
    }

    func uikitAnimator() throws -> UIViewPropertyAnimator {
        switch type {
        case .spring:
            throw TypeMissmatchError(message: "No uikitAnimator for spring type")
        case .interpolatingSpring:
            throw TypeMissmatchError(message: "No uikitAnimator for interpolatingSpring type")
        case .uikit:
            return UIViewPropertyAnimator(
                duration: uikitValue.duration,
                dampingRatio: CGFloat(uikitValue.dampingRatio),
                animations: nil
            )
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

    var parameterSettings: [(String, ClosedRange<Double>, unit: Double, Binding<Double>)] {
        switch parameter.type {
        case .spring:
            return [
                ("Response", 0.0 ... 20.00, 0.05, $parameter.springValue.response),
                ("Damping Fraction", 0.0 ... 5.0, 0.025, $parameter.springValue.dampingFraction),
                ("Blend Duration", 0.0 ... 2.0, 0.1, $parameter.springValue.blendDuration)
            ]
        case .interpolatingSpring:
            return [
                ("Mass", 0.1 ... 10.0, 0.1, $parameter.interpolatingSpringValue.mass),
                ("Stiffness", 0.1 ... 10.0, 0.1, $parameter.interpolatingSpringValue.stiffness),
                ("Damping", 0.0 ... 5.0, 0.1, $parameter.interpolatingSpringValue.damping),
                ("Initial Velocity", -10.0 ... 10.0, 0.1, $parameter.interpolatingSpringValue.initialVelocity)
            ]
        case .uikit:
            return [
                ("Duration", 0.0 ... 10.0, 0.1, $parameter.uikitValue.duration),
                ("Damping Ratio", 0.0 ... 5.0, 0.025, $parameter.uikitValue.dampingRatio)
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
                Text("UIKit")
                    .tag(SpringParameter.SpringType.uikit)
            }
            .pickerStyle(WheelPickerStyle())

            LazyVGrid(columns: columns) {
                ForEach(parameterSettings, id: \.0) { setting in
                    let (title, range, unit, property) = setting
                    Text(title)
                    Text(String(format: "%.3f", property.wrappedValue))
                    Slider(value: property, in: range)
                        .onChange(of: property.wrappedValue) { value in
                            property.wrappedValue = (value / unit).rounded() * unit
                        }
                }
            }
        }
        .background(textWidthView)
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
