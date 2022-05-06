//
//  SpringboardService.swift
//  SwiftyMobileDevice
//
//  Created by Kazuki Yamamoto on 2019/12/25.
//  Copyright © 2019 Kazuki Yamamoto. All rights reserved.
//

import Foundation
import CMobileDevice

public enum SpringboardError: Int32, Error {
    case invalidArgument = -1
    case plistError = -2
    case connectionFailed = -3
    case unknown = -256
    
    case deallocatedService = 100
}

public struct SpringboardServiceClient {
    public static func startService<T>(lockdown: LockdownClient, label: String, body: (SpringboardServiceClient) throws -> T) throws -> T {
        guard let lockdown = lockdown.rawValue else {
            throw LockdownError.deallocated
        }
        var pclient: sbservices_client_t? = nil
        let rawError = sbservices_client_start_service(lockdown, &pclient, label)
        if let error = SpringboardError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let client = pclient else {
            throw SpringboardError.unknown
        }
        var sbclient = SpringboardServiceClient(rawValue: client)
        let result = try body(sbclient)
        try sbclient.free()
        return result
    }
    
    private var rawValue: sbservices_client_t?
    
    init(rawValue: sbservices_client_t) {
        self.rawValue = rawValue
    }

    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }

        var client: sbservices_client_t? = nil
        let rawError = screenshotr_client_new(device, service, &client)
        if let error = SpringboardError(rawValue: rawError.rawValue) {
            throw error
        }
        guard client != nil else {
            throw SpringboardError.unknown
        }
        self.rawValue = client
    }
    
    public func getIconPNGData(bundleIdentifier: String) throws -> Data {
        guard let rawValue = self.rawValue else {
            throw SpringboardError.deallocatedService
        }
        var ppng: UnsafeMutablePointer<Int8>? = nil
        var size: UInt64 = 0
        let rawError = sbservices_get_icon_pngdata(rawValue, bundleIdentifier, &ppng, &size)
        if let error = SpringboardError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let png = ppng else {
            throw SpringboardError.unknown
        }
        let buffer = UnsafeMutableBufferPointer(start: png, count: Int(size))
        defer { buffer.deallocate() }
        
        return Data(buffer: buffer)
    }
    
    public func getHomeScreenWallpaperPNGData() throws -> Data {
        guard let rawValue = self.rawValue else {
            throw SpringboardError.deallocatedService
        }
        var ppng: UnsafeMutablePointer<Int8>? = nil
        var size: UInt64 = 0
        let rawError = sbservices_get_home_screen_wallpaper_pngdata(rawValue, &ppng, &size)
        if let error = SpringboardError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let png = ppng else {
            throw SpringboardError.unknown
        }
        
        let buffer = UnsafeMutableBufferPointer(start: png, count: Int(size))
        defer { buffer.deallocate() }
        
        return Data(buffer: buffer)
    }
    
    public mutating func free() throws {
        guard let rawValue = self.rawValue else {
            return
        }
        
        let rawError = sbservices_client_free(rawValue)
        if let error = SpringboardError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = nil
    }
}
