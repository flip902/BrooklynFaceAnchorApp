//
//  ChargingThrottler.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

typealias EventType = Int

public class ChargingThrottler: Throttler {
    private var currentEventType: EventType? = nil
    func throttle(eventType: EventType, block: @escaping () -> ()) {
        if currentEventType != eventType {
            self.previousRun = Date()
            currentEventType = eventType
        }
        
        super.throttle { block() }
    }
}
