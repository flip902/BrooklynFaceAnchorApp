//
//  Throttler.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

private extension Date {
    static func second(from referenceDate: Date) -> Float {
        return Float(Date().timeIntervalSince(referenceDate))
    }
}

public class Throttler {
    internal let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    internal var job: DispatchWorkItem = DispatchWorkItem(block: {})
    internal var previousRun: Date = Date.distantPast
    internal var maxInterval: Float
    
    init(seconds: Float) {
        self.maxInterval = seconds
    }
    
    func throttle(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem() { [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}
