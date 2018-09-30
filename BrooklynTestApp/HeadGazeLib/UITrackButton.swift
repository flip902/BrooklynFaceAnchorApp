//
//  UITrackButton.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-27.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

/// Hoverable button that can track cursor's time and location inside the button. Created for sensitivity analysis.
class UITrackButton: UIBubbleButton {
    // track (x,y) cursor position during hovering
    public var TrackedCursorCoords: [CGPoint] = []
    public var dwellStartTime: Date = Date()
    public var dwellEndTime: Date = Date()
    private var isStartTimeUpdated: Bool = false
    private var isEndTimeUpdated: Bool = false
    private var canTrackCoords: Bool = false
    private var internalMaxNumSamples: Int = 5
    
    public var maxNumSamples: Int {
        get { return internalMaxNumSamples }
        set {
            internalMaxNumSamples = newValue
            if internalMaxNumSamples > 0 {
                trackThrottler = ChargingThrottler(seconds: dwellDuration / Float(internalMaxNumSamples + 1))
            } else { trackThrottler = nil }
        }
    }
    
    internal var trackThrottler: ChargingThrottler? = ChargingThrottler(seconds: 1.0 / (5.0 + 1.0))
    
    /**
     Use current gaze object to update the button hovering status.
     - Parameters:
         - gaze: UIHeadGaze. The gaze object used by the button instance to get cursor location for instersection test.
         - view: The UIView instance, usually the parent of the button. The tracked cursor location is calculated w.r.t the coordinate system of the view. You can pass in it a window instance to track the global coordinates w.r.t the entire device screen. If nil, the default coordinate system is inferred from the parent of the button.
     */
    public func hover(gaze: UIHeadGaze, in view: UIView? = nil) {
        
        let cursorPos = gaze.location(in: self.superview)
        if self.frame.contains(cursorPos) {
            UIView.animate(withDuration: TimeInterval(super.dwellTime), animations: {
                self.hoverAnimation()
                
                if !self.isStartTimeUpdated {
                    self.isStartTimeUpdated = true
                    self.isEndTimeUpdated = false
                    self.canTrackCoords = true
                    self.dwellStartTime = Date()
                }
                
                if self.canTrackCoords {
                    self.trackThrottler?.throttle(eventType: EventType(0), block: {
                        var trackPos = CGPoint()
                        DispatchQueue.main.sync {
                            if let inView = view {
                                trackPos = gaze.location(in: inView)
                            } else {
                                trackPos = gaze.location(in: self.superview)
                            }
                        }
                        self.TrackedCursorCoords.append(trackPos)
                    })
                }
            }, completion: {(finished: Bool) in
                self.throttler?.throttle(eventType: EventType(1), block: {
                    if !self.isEndTimeUpdated {
                        self.isEndTimeUpdated = true
                        self.canTrackCoords = false
                        self.dwellEndTime = Date()
                    }
                    DispatchQueue.main.async {
                        super.internalSelect()
                    }
                })
            })
        } else {
            UIView.animate(withDuration: TimeInterval(super.dwellTime), animations: {
                self.TrackedCursorCoords.removeAll()
                self.deHoverAnimation()
            }, completion: {(finished: Bool) in
                self.throttler?.throttle(eventType: EventType(-1), block: {
                    super.internalSelect()
                })
            })
        }
    }
}
