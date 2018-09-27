//
//  UIHoverableButton.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-27.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

/**
 By default the hoverable button increases it's size when the cursor is hovering over it, and
 triggers a selection action when it completes it's dialation animation. Similarily, it decreases it's
 size, and triggers deselection action when it completes its shrinking animation.
 
 Subclass of UIHoverableButton can customize the animation of hovering by overriding methods:
 - `hoverAnimation()`
 - `deHoverAnimation()`
 
 override methods `select()` and `deselect()` to define what to do whenever the button completes animation.
 */
class UIHoverableButton: UIButton {
    // MARK: - Property Declarations
    public var name: String = "untitled"
    public var hoverScale: Float = 1.3
    public var inAlpha: CGFloat = 1.0
    public var outAlpha: CGFloat = 0.5
    public var enableHapticFeedBack: Bool = true
    
    public var dwellDuration: Float {
        set {
            dwellTime = newValue
            throttler = ChargingThrottler(seconds: dwellTime)
        }
        get {
            return dwellTime
        }
    }
    internal var dwellTime: Float = 1
    internal var throttler: ChargingThrottler? = ChargingThrottler(seconds: 1)
    internal var isSelect: Bool = false
    
    internal let feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // MARK: - Class Methods
    /// **Overridable**. Override this method to define the behavior when the button is selected
    public func select() {}
    internal func internalSelect() {
        if !self.isSelect {
            self.isSelect = true
            DispatchQueue.main.async {
                self.feedbackGenerator.impactOccurred()
                self.sendActions(for: .touchUpInside)
                self.select()
            }
        }
    }
    
    /// **Overridable**. Define the behaviour when button is deselected.
    public func deselect() {}
    internal func internalDeselect() {
        if self.isSelect {
            self.isSelect = false
            DispatchQueue.main.async {
                self.sendActions(for: .touchUpOutside)
                self.deselect()
            }
        }
    }
    
    /// **Overridable**. Define the animation when cursor is hovering over the button.
    public func hoverAnimation() {
        self.alpha = self.inAlpha
        self.transform = CGAffineTransform(scaleX: CGFloat(hoverScale), y: CGFloat(hoverScale))
    }
    
    /// **Overridable**. Define the animation when the cursor touches outside the button.
    public func deHoverAnimation() {
        self.alpha = self.outAlpha
        self.transform = .identity
    }
    
    /**
      Call the function with gaze object that is used by the button to
      determine intersection and to perform animation for hover duration.
      - Parameters:
        - gaze: A UIHeadGaze object with gaze location
    */
    public func hover(gaze: UIHeadGaze) {
        let headCursorPos = gaze.location(in: self.superview)
        if self.frame.contains(headCursorPos) {
            UIView.animate(withDuration: TimeInterval(dwellTime), animations: {() -> Void in
                self.hoverAnimation()
            }, completion: {(finished: Bool) in
                self.throttler?.throttle(eventType: EventType(1), block: { self.internalSelect() })
            })
        } else {
            UIView.animate(withDuration: TimeInterval(dwellTime), animations: {
                self.deHoverAnimation()
            }, completion: {(finished: Bool) in
                self.throttler?.throttle(eventType: EventType(-1), block: { self.internalDeselect() })
            })
        }
    }
 
}
