//
//  File.swift
//  
//
//  Created by Kazuki Yamamoto on 2022/04/24.
//

import Foundation
import CMobileDevice

public struct AFCFile {
    let handle: UInt64
    private let client: AFCClient

    init(client: AFCClient, handle: UInt64) {
        self.client = client
        self.handle = handle
    }

    public init(client: AFCClient, filename: String, mode: AFCFileMode) throws {
        var handle: UInt64 = 0
        if let error = AFCClientError(afc_file_open(client.rawValue, filename, afc_file_mode_t(mode.rawValue), &handle)) {
            throw error
        }

        self.client = client
        self.handle = handle
    }

    public func lock(operation: AFCLockOperation) throws {
        if let error = AFCClientError(afc_file_lock(client.rawValue, handle, afc_lock_op_t(operation.rawValue))) {
            throw error
        }
    }

    public func read(length: UInt32) throws -> Data {
        let data = UnsafeMutablePointer<CChar>.allocate(capacity: Int(length))
        var bytesRead: UInt32 = 0
        if let error = AFCClientError(afc_file_read(client.rawValue, handle, data, length, &bytesRead)) {
            throw error
        }

        defer { data.deallocate() }
        let buffer = UnsafeBufferPointer(start: data, count: Int(bytesRead))
        return Data(buffer: buffer)
    }

    public func close() {
        afc_file_close(client.rawValue, handle)
    }
}

public extension AFCClient {
    static func start<T>(device: Device, action: (AFCClient) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }

        var pclient: afc_client_t?
        if let error = AFCClientError(afc_client_start_service(device, &pclient, nil)) {
            throw error
        }
        guard let rawValue = pclient else {
            throw AFCClientError.unknown
        }

        var client = AFCClient(rawValue: rawValue)
        defer { client.free() }

        return try action(client)
    }
}
