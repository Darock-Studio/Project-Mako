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
let gotoAlbumSubject = PassthroughSubject<Int64, Never>()
let gotoArtistSubject = PassthroughSubject<Int, Never>()
let presentCommentsSubject = PassthroughSubject<Int64, Never>()
