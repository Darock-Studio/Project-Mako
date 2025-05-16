//
//  Identifiable.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/16.
//

import Foundation

extension Int64: @retroactive Identifiable {
    public var id: Self { self }
}
