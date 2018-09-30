//
//  UIMultiFuncButton.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-29.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

class UIMultiFuncButton: UIBubbleButton {
    private var clickCount = 0
    internal var darkFillView2: UIView? = nil
    internal var longDwellTime: Float = 2
    internal var throttler2: ChargingThrottler? = ChargingThrottler(seconds: 2)
    public var longDwellDuration: Float {
        set {
            longDwellTime = newValue
            throttler2 = ChargingThrottler(seconds: longDwellTime)
        }
        get {
            return longDwellTime
        }
    }
    
    override internal func setupUI(frame: CGRect) {
        let w = frame.width
        let h = frame.height
        self.clipsToBounds = true
        super.outAlpha = 0.1
        self.hoverScale = Float(max(w, h))
        
        self.layer.cornerRadius = min(w, h) / 5.0
        self.setTitleColor(UIColor.black, for: .normal)
        self.backgroundColor = UIColor.white
        self.alpha = 1.0
        
        let dummyFrame = CGRect(x: w/2, y: h/2, width: 1, height: 1)
        darkFillView = UIView(frame: dummyFrame)
        darkFillView?.backgroundColor = .blue
        darkFillView?.layer.cornerRadius = 0.5
        addSubview(darkFillView!)
    }
    
    /// **Overridable**. Define the animation when cursor is long hovering over the button
    func hoverAnimation2() {
        self.darkFillView2?.alpha = self.inAlpha
        self.darkFillView2?.transform = CGAffineTransform(scaleX: CGFloat(hoverScale), y: CGFloat(hoverScale))
    }
    
    /// **Overridable**. Define the animation when cursor leaves the button after long hovering.
    public func deHoverAnimation2() {
        DispatchQueue.main.async {
            self.darkFillView2?.alpha = self.outAlpha
            self.darkFillView2?.transform = .identity
        }
    }
    
    private func internalSecondSelect() {
        if self.clickCount == 1 {
            self.isSelect = true
            DispatchQueue.main.async {
                self.feedbackGenerator.impactOccurred()
                self.sendActions(for: .touchDownRepeat)
                self.select()
            }
        }
    }
    
    /**
      Call the function with gaze object that is used by the button to determine intersection and perform relevant animation for hovering duration
     - Parameters:
         - gaze: a `UIHeadGaze` object with gaze location
    */
    override public func hover(gaze: UIHeadGaze) {
        let headCursorPos = gaze.location(in: self.superview)
        if self.frame.contains(headCursorPos) {
            UIView.animateKeyframes(withDuration: TimeInterval(longDwellTime), delay: 0, options: [.calculationModeCubic], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: Double(self.dwellTime / self.longDwellTime), animations: {
                    self.hoverAnimation()
                })
                UIView.addKeyframe(withRelativeStartTime: Double(self.dwellTime / self.longDwellTime), relativeDuration: Double((self.longDwellTime - self.dwellTime) / self.longDwellTime), animations: {
                    self.deHoverAnimation2()
                })
            }) { (_) in
                self.throttler?.throttle(eventType: EventType(1), block: {
                    self.internalSelect()
                    self.clickCount = 1
                })
                self.throttler2?.throttle(eventType: EventType(1), block: {
                    self.internalSecondSelect()
                    self.deHoverAnimation2()
                })
            }
        } else {
            UIView.animate(withDuration: TimeInterval(dwellTime), animations: {
                self.deHoverAnimation()
                self.deHoverAnimation2()
            }, completion: {(finished: Bool) in
                self.throttler?.throttle(eventType: EventType(0), block: {
                    self.internalDeselect()
                    self.clickCount = 0
                })
                self.throttler2?.throttle(eventType: EventType(0), block: { })
            })
        }
    }
 
}
