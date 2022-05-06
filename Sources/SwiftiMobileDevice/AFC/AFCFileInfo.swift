//
//  File.swift
//  
//
//  Created by Kazuki Yamamoto on 2022/04/24.
//

import Foundation

public struct AFCFileInfo {
    public struct ParseError: Error {
        let invalidKey: String
        let actualKey: String?
        let actualValue: String?
    }
    public enum FileType: String {
        case socket = "S_IFSOCK"
        case symbolicLink = "S_IFLNK"
        case file = "S_IFREG"
        case blockDevice = "S_IFBLK"
        case directory = "S_IFDIR"
        case characterDevice = "S_IFCHR"
        case fifo = "S_IFIFO"
    }

    public let size: Int
    public let blocks: Int
    public let linkCount: Int
    public let type: FileType?
    public let createdAt: Date
    public let updatedAt: Date

    init(_ info: [String]) throws {
        self.size = try value(array: info, key: "st_size", index: 0, transform: Int.init)
        self.blocks = try value(array: info, key: "st_blocks", index: 2, transform: Int.init)
        self.linkCount = try value(array: info, key: "st_nlink", index: 4, transform: Int.init)
        self.type = try value(array: info, key: "st_ifmt", index: 6, transform: FileType.init)
        self.updatedAt = try value(array: info, key: "st_mtime", index: 8, transform: makeDate(from:))
        self.createdAt = try value(array: info, key: "st_birthtime", index: 10, transform: makeDate(from:))
    }
}

private func value<T>(array: [String], key: String, index: Int, transform: (String) -> T?) throws -> T {
    let count = array.count
    guard index < count else {
        throw AFCFileInfo.ParseError(invalidKey: key, actualKey: nil, actualValue: nil)
    }
    guard array[index] == key, index + 1 < count else {
        throw AFCFileInfo.ParseError(invalidKey: key, actualKey: array[count], actualValue: nil)
    }

    guard let transformed = transform(array[index + 1]) else {
        throw AFCFileInfo.ParseError(invalidKey: key, actualKey: key, actualValue: array[index + 1])
    }

    return transformed
}

private func makeDate(from string: String) -> Date? {
    guard let interval = Double(string) else {
        return nil
    }

    return Date.init(timeIntervalSince1970: interval / 1000_000_000)
}
