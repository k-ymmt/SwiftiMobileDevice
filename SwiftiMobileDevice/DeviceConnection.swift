//
//  DeviceConnection.swift
//  SwiftyMobileDevice
//
//  Created by Kazuki Yamamoto on 2019/12/25.
//  Copyright © 2019 Kazuki Yamamoto. All rights reserved.
//

import Foundation
import MobileDevice

public struct DeviceConnection {
    var rawValue: idevice_connection_t?
    
    init(rawValue: idevice_connection_t) {
        self.rawValue = rawValue
    }

    init() {
        self.rawValue = nil
    }
    
    public func send(data: Data) throws -> UInt32 {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }

        return try data.withUnsafeBytes { (pdata) -> UInt32 in
            var sentBytes: UInt32 = 0
            let pdata = pdata.baseAddress?.bindMemory(to: Int8.self, capacity: data.count)
            let rawError = idevice_connection_send(rawValue, pdata, UInt32(data.count), &sentBytes)
            if let error = MobileDeviceError(rawValue: rawError.rawValue) {
                throw error
            }
            
            return sentBytes
        }
    }
    
    public func receive(timeout: UInt32? = nil, length: UInt32) throws -> (Data, UInt32) {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        
        let pdata = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
        defer { pdata.deallocate() }
        let rawError: idevice_error_t
        var receivedBytes: UInt32 = 0
        if let timeout = timeout {
            rawError = idevice_connection_receive_timeout(rawValue, pdata, length, &receivedBytes, timeout)
        } else {
            rawError = idevice_connection_receive(rawValue, pdata, length, &receivedBytes)
        }
        
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        let buffer = UnsafeBufferPointer<Int8>(start: pdata, count: Int(receivedBytes))

        return (Data(buffer: buffer), receivedBytes)
    }
    
    public func setSSL(enable: Bool) throws {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        if enable {
            idevice_connection_enable_ssl(rawValue)
        } else {
            idevice_connection_disable_ssl(rawValue)
        }
    }
    
    public func getFileDescriptor() throws -> Int32 {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        var fd: Int32 = 0
        let rawError = idevice_connection_get_fd(rawValue, &fd)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return fd
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        idevice_disconnect(rawValue)
        self.rawValue = nil
    }
}
