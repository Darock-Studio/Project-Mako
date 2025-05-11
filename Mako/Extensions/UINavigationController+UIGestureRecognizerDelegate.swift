//
//  UINavigationController+UIGestureRecognizerDelegate.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/11.
//

#if os(iOS)

import UIKit

// rdar://so?59921239
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

#endif
