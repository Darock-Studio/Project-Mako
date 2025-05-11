//
//  View+ReversedMask.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import SwiftUI

extension View {
    public func reversedMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
            }
    }
}

