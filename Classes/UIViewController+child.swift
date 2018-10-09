//
//  UIViewController+child.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import Foundation
import UIKit

extension UIViewController {
    public func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    public func addFilling(_ child: UIViewController) {
        child.view.translatesAutoresizingMaskIntoConstraints = false
        add(child)
        
        let margins = view.layoutMarginsGuide
        child.view.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        child.view.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        child.view.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        child.view.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
    }
    
    public func remove() {
        if parent == nil {
            return
        }
        
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}
