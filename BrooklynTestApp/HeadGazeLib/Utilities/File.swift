//
//  File.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import simd

extension matrix_float4x4: CustomStringConvertible {
    public var debugDescription: String {
        let m = self
        return """
        \(m[0][0]), \(m[1][0]), \(m[2][0]), \(m[3][0])
        \(m[0][1]), \(m[1][1]), \(m[2][1]), \(m[3][1])
        \(m[0][2]), \(m[1][2]), \(m[2][2]), \(m[3][2])
        \(m[0][3]), \(m[1][3]), \(m[2][3]), \(m[3][3])
        """
    }
    
    public var description: String {
        return self.debugDescription
    }
    
    public static let identity: matrix_float4x4 = matrix_float4x4(columns: (simd_float4(1,0,0,0), simd_float4(0,1,0,0), simd_float4(0,0,1,0), simd_float4(0,0,0,1)))
}

extension BinaryInteger {
    var degreesToRadians: Float {
        return Float(Int(self)) * .pi / 180.0
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
