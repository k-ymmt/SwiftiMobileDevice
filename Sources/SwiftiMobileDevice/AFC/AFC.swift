//
//  File.swift
//  
//
//  Created by Kazuki Yamamoto on 2022/04/24.
//

import Foundation
import CMobileDevice

public enum AFCClientError: Int32, Error {
    case unknown = 1
    case opHeaderInvalid
    case noResources
    case readError
    case writeError
    case unknownPacketType
    case invalidArgument
    case objectNotFound
    case objectIsDirectory
    case permissionDenied
    case serviceNotConnected
    case operationTimeout
    case tooMuchData
    case endOfData
    case operationNotSupported
    case objectExists
    case objectBusy
    case spaceLeft
    case wouldBlock
    case ioError
    case operationInterrupted
    case operationInProgress
    case internalError
    case muxError
    case noMemory
    case notEnoughData
    case directoryNotEmpty
    case forceSignedType = -1

    init?(_ error: afc_error_t) {
        self.init(rawValue: error.rawValue)
    }
}

public enum AFCDeviceInfoKey: String {
    case model = "Model"
    case totalBytes = "FSTotalBytes"
    case freeBytes = "FSFreeBytes"
    case blockSize = "FSBlockSize"
}

public enum AFCFileMode: UInt32 {
    case readOnly = 0x00000001
    case readAndWrite = 0x00000002
    case writeOnly = 0x00000003
    case write = 0x00000004
    case append = 0x00000005
    case readAndAppend = 0x00000006
}

public enum AFCLockOperation: UInt32 {
    case sharedLock = 5
    case exclusiveLock = 6
    case unlock = 12
}

public struct AFCClient {
    var rawValue: afc_client_t?

    init(rawValue: afc_client_t) {
        self.rawValue = rawValue
    }

    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.deallocated
        }

        var pclient: afc_client_t?
        if let error = AFCClientError(afc_client_new(device, service, &pclient)) {
            throw error
        }

        self.rawValue = pclient
    }

    public func getDeviceInfo() throws -> [String] {
        var information: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        if let error = AFCClientError(afc_get_device_info(rawValue, &information)) {
            throw error
        }
        guard let information = information else {
            return []
        }

        defer { afc_dictionary_free(information) }
        return makeStringArray(from: information)
    }

    public func deviceInfo(from key: AFCDeviceInfoKey) throws -> String? {
        var info: UnsafeMutablePointer<CChar>?
        if let error = AFCClientError(afc_get_device_info_key(rawValue, key.rawValue, &info)) {
            throw error
        }

        guard let info = info else {
            return nil
        }

        defer { info.deallocate() }
        return String(cString: info)
    }

    public func readDirectory(path: String) throws -> [String] {
        var dictionary: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        if let error = AFCClientError(afc_read_directory(rawValue, path, &dictionary)) {
            throw error
        }

        guard let dictionary = dictionary else {
            return []
        }

        defer { afc_dictionary_free(dictionary) }

        return makeStringArray(from: dictionary)
    }

    public func rawFileInfo(path: String) throws -> [String] {
        var infomation: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        if let error = AFCClientError(afc_get_file_info(rawValue, path, &infomation)) {
            throw error
        }

        guard let infomation = infomation else {
            return []
        }

        defer { afc_dictionary_free(infomation) }

        return makeStringArray(from: infomation)
    }

    public func fileInfo(path: String) throws -> AFCFileInfo {
        let rawFileInfo = try rawFileInfo(path: path)
        return try AFCFileInfo(rawFileInfo)
    }

    public func openFile<T>(path: String, mode: AFCFileMode, action: (AFCFile) throws -> T) throws -> T {
        let file = try AFCFile(client: self, filename: path, mode: mode)
        defer { file.close() }
        try file.lock(operation: .sharedLock)
        let output = try action(file)
        try file.lock(operation: .unlock)
        return output
    }

    public func readFile(path: String) throws -> Data {
        let info = try rawFileInfo(path: path)
        guard
            let index = info.firstIndex(of: "st_size"),
            index + 1 < info.count,
            let size = UInt32(info[index + 1])
        else {
            throw AFCClientError.readError
        }

        return try openFile(path: path, mode: .readOnly) { file in
            try file.read(length: size)
        }
    }

    public mutating func free() {
        guard let rawValue = rawValue else {
            return
        }

        afc_client_free(rawValue)
        self.rawValue = nil
    }
}


func makeStringArray(from pointer: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> [String] {
    var i = 0
    var list: [String] = []
    while let pointer = pointer.advanced(by: i).pointee {
        list.append(String(cString: pointer))
        i += 1
    }

    return list
}
