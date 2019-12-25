//
//  SwiftyLibPlistTests.swift
//  SwiftyLibPlistTests
//
//  Created by Kazuki Yamamoto on 2019/11/28.
//  Copyright © 2019 Kazuki Yamamoto. All rights reserved.
//

import XCTest
@testable import SwiftyLibPlist

private let xml = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>test1</key>
    <string>foo</string>
    <key>test2</key>
    <integer>10000</integer>
    <key>tests</key>
    <array>
        <true/>
        <false/>
        <true/>
    </array>
    <key>dict</key>
    <dict>
        <key>array</key>
        <array>
            <dict>
                <key>hoge</key>
                <string>hoge</string>
            </dict>
        </array>
    </dict>
</dict>
</plist>
"""

class SwiftyLibPlistTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadFromXMLString() {
        guard let plist = Plist(xml: xml) else {
            XCTFail("plist making failure")
            return
        }

        guard let test1 = plist["test1"] else {
            XCTFail("test1 not found")
            return
        }
        
        XCTAssertEqual(test1.string, "foo")
    }
    
    func testChaining() {
        guard let plist = Plist(xml: xml) else {
            XCTFail("plist making failure")
            return
        }
        
        let result = plist["dict"]!["array"]![0]!["hoge"]!.string
        XCTAssertEqual(result, "hoge")
        
    }
    
    func testInit() {
        let now = Date(timeIntervalSinceReferenceDate: 100000.100000)
        let dict = Plist(dictionary: [
            "test1": Plist(string: "hoge"),
            "test2": Plist(array: [
                Plist(bool: true),
                Plist(data: "foo".data(using: .utf8)!),
                Plist(real: 0.001),
                Plist(uint: 10000),
                Plist(uid: 10001),
                Plist(date: now)
            ])
        ])
        print(dict.xml()!)
        XCTAssertEqual(dict["test1"]?.string, "hoge")
        let test2 = dict["test2"]!
        XCTAssertEqual(test2[0]?.bool, true)
        XCTAssertEqual(test2[1]?.data, "foo".data(using: .utf8))
        XCTAssertEqual(test2[2]?.real, 0.001)
        XCTAssertEqual(test2[3]?.uint, 10000)
        XCTAssertEqual(test2[4]?.uid, 10001)
        XCTAssertEqual(test2[5]?.date, now)
    }
}
