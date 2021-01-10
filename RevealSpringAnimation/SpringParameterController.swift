//
//  SpringParameterController.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/31.
//

import SwiftUI
import UIKit

struct SpringParameter {
    enum SpringType: Hashable, CaseIterable {
        case spring
        case interpolatingSpring
        case uikit
        case coreAnimation

        var name: LocalizedStringKey {
            switch self {
            case .spring:
                return "Spring"
            case .interpolatingSpring:
                return "Interpolating Spring"
            case .uikit:
                return "UIKit"
            case .coreAnimation:
                return "Core Animation"
            }
        }
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
        var initialVelocity: Double = 0.0
    }

    struct CASpring {
        var mass: Double = 1.0
        var stiffness: Double = 1.0
        var damping: Double = 1.0
        var initialVelocity: Double = 0.0
    }

    struct TypeMissmatchError: Error {
        var message: String
    }

    var type = SpringType.spring

    var springValue = Spring()
    var interpolatingSpringValue = InterpolatingSpring()
    var uikitValue = UIKitSpring()
    var caValue = CASpring()

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
        case .coreAnimation:
            throw TypeMissmatchError(message: "No animation for coreAnimation type")
        }
    }

    func uikitAnimator() throws -> UIKitSpring {
        switch type {
        case .spring:
            throw TypeMissmatchError(message: "No uikitAnimator for spring type")
        case .interpolatingSpring:
            throw TypeMissmatchError(message: "No uikitAnimator for interpolatingSpring type")
        case .uikit:
            return uikitValue
        case .coreAnimation:
            throw TypeMissmatchError(message: "No uikitAnimator for coreAnimation type")
        }
    }

    func caAnimation() throws -> CASpring {
        switch type {
        case .spring:
            throw TypeMissmatchError(message: "No caAnimation for spring type")
        case .interpolatingSpring:
            throw TypeMissmatchError(message: "No caAnimation for interpolatingSpring type")
        case .uikit:
            throw TypeMissmatchError(message: "No caAnimation for uikit type")
        case .coreAnimation:
            return caValue
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
                ("Damping Ratio", 0.0 ... 5.0, 0.025, $parameter.uikitValue.dampingRatio),
                ("Initial Velocity", -10.0 ... 10.0, 0.1, $parameter.uikitValue.initialVelocity)
            ]
        case .coreAnimation:
            return [
                ("Mass", 0.1 ... 10.0, 0.1, $parameter.caValue.mass),
                ("Stiffness", 0.1 ... 10.0, 0.1, $parameter.caValue.stiffness),
                ("Damping", 0.0 ... 5.0, 0.1, $parameter.caValue.damping),
                ("Initial Velocity", -10.0 ... 10.0, 0.1, $parameter.caValue.initialVelocity)
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
                ForEach(SpringParameter.SpringType.allCases, id: \.self) { type in
                    Text(type.name)
                }
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
