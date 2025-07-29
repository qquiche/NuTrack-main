//
//  KeyboardHiding.swift
//  NuTrack
//
//  Created by Anthony Rojas on 4/9/25.
//

// Put this piece of code anywhere you like

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
