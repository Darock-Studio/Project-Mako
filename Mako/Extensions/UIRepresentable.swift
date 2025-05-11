//
//  UIRepresentable.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI

struct GenericUIViewRepresentable: UIViewRepresentable {
    var view: UIView
    func makeUIView(context: Context) -> some UIView {
        view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
