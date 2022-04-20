//
//  SwiftiMobileDeviceTests.swift
//  SwiftiMobileDeviceTests
//
//  Created by Kazuki Yamamoto on 2019/12/25.
//  Copyright © 2019 Kazuki Yamamoto. All rights reserved.
//

import XCTest
@testable import SwiftiMobileDevice

private let udid = "test"
private let port: UInt = 8555

class SwiftiMobileDeviceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFoo() throws {
        let device = try Device(udid: "test")
        let lockdown =
            try LockdownClient(device: device, withHandshake: true)
        
        try lockdown.startService(service: .syslogRelay, withEscroBag: false) { (service) throws -> Void in
            let client = try SyslogRelayClient(device: device, service: service)

            _ = try client.startCaptureMessage(callback: { (data) in
                print("hoge")
                print(data)
            })
        }
        
        
        sleep(30)
    }

    func testReceiveMessage() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let device = try Device(udid: udid)
        let connection = try device.connect(port: port)
        do {
            let native = NativeDeviceConnection(sock: try connection.getFileDescriptor())
            DispatchQueue.global().async {
                do {
                    try native.start()
                } catch {
                    print(error)
                }
            }
            native.receive { (data) in
                print(data)
            }
        }
        
        sleep(5000)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
