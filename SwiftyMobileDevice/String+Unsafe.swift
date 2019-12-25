//
//  String+Unsafe.swift
//  SwiftyMobileDevice
//
//  Created by Kazuki Yamamoto on 2019/12/25.
//  Copyright © 2019 Kazuki Yamamoto. All rights reserved.
//

import Foundation

extension String {
    func unsafeMutablePointer() -> UnsafeMutablePointer<Int8>? {
        let cString = utf8CString
        let buffer = UnsafeMutableBufferPointer<Int8>.allocate(capacity: cString.count)
        _ = buffer.initialize(from: cString)
        
        return buffer.baseAddress
    }
    
    func unsafePointer() -> UnsafePointer<Int8>? {
        return UnsafePointer<Int8>(unsafeMutablePointer())
    }
}
