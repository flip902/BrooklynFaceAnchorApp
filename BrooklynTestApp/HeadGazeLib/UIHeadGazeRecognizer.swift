//
//  UIHeadGazeRecognizer.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIHeadGazeRecognizer: UIGestureRecognizer {
    var move: ((UIHeadGaze) -> ())?
    func gazeMoved(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?) {
        state = .changed
        move?(gazes.first!)
    }
}
