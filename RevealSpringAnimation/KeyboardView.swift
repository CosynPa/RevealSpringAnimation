//
//  KeyboardView.swift
//  RevealSpringAnimation
//
//  Created by Pan Yusheng on 2021/2/7.
//

import Foundation
import UIKit
import SwiftUI

struct CustomKeyboardTextField: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.borderStyle = .roundedRect
        view.placeholder = "Tap here to show the blank keyboard"
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.inputView = KeyboardView()
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {

    }
}

class KeyboardView: UIView {
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false

        let dismiss = UIButton(type: .system)
        dismiss.setTitle("Dismiss Keyboard", for: .normal)
        dismiss.addTarget(self, action: #selector(KeyboardView.dismissTapped(_:)), for: .touchUpInside)

        dismiss.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dismiss)

        NSLayoutConstraint.activate([
            dismiss.centerXAnchor.constraint(equalTo: centerXAnchor),
            dismiss.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc
    func dismissTapped(_ sender: UIButton) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}
