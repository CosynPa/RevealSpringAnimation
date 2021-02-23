//
//  SpringParameterController.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2020/12/31.
//

import SwiftUI
import UIKit

enum SpringType: Hashable, CaseIterable, Equatable {
    case spring
    case interpolatingSpring
    case uikit
    case coreAnimation
    case keyboard

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
        case .keyboard:
            return "Keyboard"
        }
    }
}

// SwiftUI spring API parameters
struct Spring {
    var response: Double = 0.55
    var dampingFraction: Double = 0.825
    var blendDuration: Double = 0

    var animation: Animation {
        .spring(
            response: response,
            dampingFraction: dampingFraction,
            blendDuration: blendDuration
        )
    }
}

// SwiftUI interpolatingSpring API parameters
struct InterpolatingSpring {
    var mass: Double = 1.0
    var stiffness: Double = 1.0
    var damping: Double = 1.0
    var initialVelocity: Double = 0.0

    var animation: Animation {
        .interpolatingSpring(
            mass: mass,
            stiffness: stiffness,
            damping: damping,
            initialVelocity: initialVelocity
        )
    }
}

// UIView spring animate API parameters
struct UIKitSpring {
    var duration: Double = 0.5
    var dampingRatio: Double = 1.0
    var initialVelocity: Double = 0.0
}

// CASpringAnimation API parameters
struct CASpring {
    var mass: Double = 1.0
    var stiffness: Double = 1.0
    var damping: Double = 1.0
    var initialVelocity: Double = 0.0

    var omega: Double {
        sqrt(stiffness / mass)
    }

    var dampingRatio: Double {
        min(1.0, damping / 2 / sqrt(stiffness * mass))
    }
}

// The parameters of the whole controller, can be one of the four types
enum MultiSpringParameter {
    case spring(Spring)
    case interpolatingSpring(InterpolatingSpring)
    case uikit(UIKitSpring)
    case coreAnimation(CASpring)
    case keyboard

    var isKeyboard: Bool {
        switch self {
        case .keyboard:
            return true
        default:
            return false
        }
    }
}

@propertyWrapper
struct MultiSpringParameterEdit: DynamicProperty {
    var wrappedValue: MultiSpringParameter {
        switch type {
        case .spring:
            return .spring(springValue)
        case .interpolatingSpring:
            return .interpolatingSpring(interpolatingSpringValue)
        case .uikit:
            return .uikit(uikitValue)
        case .coreAnimation:
            return .coreAnimation(caValue)
        case .keyboard:
            return .keyboard
        }
    }

    var projectedValue: MultiSpringParameterEdit {
        self
    }

    @State var type: SpringType = .spring

    @State fileprivate var springValue = Spring()
    @State fileprivate var interpolatingSpringValue = InterpolatingSpring()
    @State fileprivate var uikitValue = UIKitSpring()
    @State fileprivate var caValue = CASpring()
}

struct MultiSpringParameterController: View {
    var editingParameter: MultiSpringParameterEdit

    var body: some View {
        VStack {
            Picker("Type", selection: editingParameter.$type) {
                ForEach(SpringType.allCases, id: \.self) { type in
                    Text(type.name)
                }
            }
            .pickerStyle(WheelPickerStyle())

            switch editingParameter.type {
            case .spring:
                OneSpringParameterController(parameter: editingParameter.$springValue,
                                             parameterSettings: [
                                                (\.response, "Response", 0.0 ... 20.00, 0.05),
                                                (\.dampingFraction, "Damping Fraction", 0.0 ... 5.0, 0.025),
                                                (\.blendDuration, "Blend Duration", 0.0 ... 2.0, 0.1)
                                             ])
            case .interpolatingSpring:
                OneSpringParameterController(parameter: editingParameter.$interpolatingSpringValue,
                                             parameterSettings: [
                                                (\.mass, "Mass", 0.1 ... 10.0, 0.1),
                                                (\.stiffness, "Stiffness", 0.1 ... 10.0, 0.1),
                                                (\.damping, "Damping", 0.0 ... 5.0, 0.1),
                                                (\.initialVelocity, "Initial Velocity", -10.0 ... 10.0, 0.1)
                                             ])
            case .uikit:
                OneSpringParameterController(parameter: editingParameter.$uikitValue,
                                             parameterSettings: [
                                                (\.duration, "Duration", 0.0 ... 10.0, 0.1),
                                                (\.dampingRatio, "Damping Ratio", 0.0 ... 5.0, 0.025),
                                                (\.initialVelocity, "Initial Velocity", -10.0 ... 10.0, 0.1)
                                             ])
            case .coreAnimation:
                OneSpringParameterController(parameter: editingParameter.$caValue,
                                             parameterSettings: [
                                                (\.mass, "Mass", 0.1 ... 10.0, 0.1),
                                                (\.stiffness, "Stiffness", 0.1 ... 10.0, 0.1),
                                                (\.damping, "Damping", 0.0 ... 5.0, 0.1),
                                                (\.initialVelocity, "Initial Velocity", -10.0 ... 10.0, 0.1),
                                             ])
            case .keyboard:
                EmptyView()
            }
        }
    }
}

struct OneSpringParameterController<Parameter>: View {
    @Binding var parameter: Parameter

    var parameterSettings: [(WritableKeyPath<Parameter, Double>, title: String, numberRange: ClosedRange<Double>, unit: Double)]

    @State var textWidth: CGFloat = 100

    var columns: [GridItem] {
        [
            GridItem(.fixed(textWidth), alignment: .leading),
            GridItem(.fixed(60), alignment: .trailing),
            GridItem(.flexible())
        ]
    }

    // This view is used to get the maximum text width, the value is set to `textWidth`
    @ViewBuilder
    var textWidthView: some View {
        VStack {
            ForEach(parameterSettings, id: \.0) { (item) in
                Text(item.title)
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
        LazyVGrid(columns: columns) {
            ForEach(parameterSettings, id: \.0) { setting in
                let (keyPath, title, range, unit) = setting
                Text(title)
                Text(String(format: "%.3f", parameter[keyPath: keyPath]))
                Slider(value: _parameter[dynamicMember: keyPath], in: range)
                    .onChange(of: parameter[keyPath: keyPath]) { value in
                        let old = parameter[keyPath: keyPath]
                        let new = (value / unit).rounded() * unit

                        if abs(new - old) > 0.001 {
                            parameter[keyPath: keyPath] = new
                        }
                    }
            }
        }
        .background(textWidthView)
    }
}

struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? {
        nil
    }

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {

    }
}

struct SpringParameterController_Previews: PreviewProvider {
    struct Wrapper: View {
        @MultiSpringParameterEdit var parameter: MultiSpringParameter

        var body: some View {
            MultiSpringParameterController(editingParameter: $parameter)
        }
    }

    static var previews: some View {
        Wrapper()
    }
}
