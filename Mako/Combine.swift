//
//  Combine.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import Combine
import Foundation

let performSearchSubject = PassthroughSubject<String, Never>()
let updateSystemVolumeSubject = PassthroughSubject<Float, Never>()
