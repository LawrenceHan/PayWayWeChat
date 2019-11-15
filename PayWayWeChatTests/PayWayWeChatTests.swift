//
//  PayWayWeChatTests.swift
//  PayWayWeChatTests
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//

import XCTest
@testable import PayWayWeChat

class PayWayWeChatTests: XCTestCase {

    override func setUp() {
        WXPay.default.registerApp(appId: WXPay.default.debug_appId, universalLink: WXPay.default.debug_universalLink)
        WXPay.default.callbackTimeout = callbackTimeout
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /// when `url` is incorrect, it should returns a failure result that contains a `responseError`
    func testIncorrectURL() {
        let request = URLRequest(url: URL(string: "https://www.baidu.com")!)
        let expectation = self.expectation(description: "testIncorrectURL")
        
        _ = WXPay.default.prePayRequest(with: request) { result in
            expectation.fulfill()
            
            if case .failure(let error) = result {
                print("[PayWayWeChatTests] \(error)")
                guard case .responseError = error else {
                    XCTFail("WXPayError.responseError was expected")
                    return
                }
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    /// when `URLRequest` is timeout, it should returns a failure result that contains a `connectionError`
    func testRequestTimeout() {
        var request = URLRequest(url: URL(string: WXPay.default.debug_url)!)
        request.timeoutInterval = 0.05
        let expectation = self.expectation(description: "testRequestTimeout")
        
        _ = WXPay.default.prePayRequest(with: request) { result in
            expectation.fulfill()
            
            if case .failure(let error) = result {
                print("[PayWayWeChatTests] \(error)")
                guard case .connectionError = error else {
                    XCTFail("WXPayError.connectionError was expected")
                    return
                }
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    /// when `task` is cancelled, it should returns a failure result that contains a `connectionError`
    func testTaskCancelled() {
        let request = URLRequest(url: URL(string: WXPay.default.debug_url)!)
        let expectation = self.expectation(description: "testTaskCancelled")
        
        let task = WXPay.default.prePayRequest(with: request) { result in
            expectation.fulfill()
            
            if case .failure(let error) = result {
                print("[PayWayWeChatTests] \(error)")
                guard case .connectionError = error else {
                    XCTFail("WXPayError.connectionError was expected")
                    return
                }
            }
        }
        
        task.cancel()
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    /// when launch `WeChat` app with `prepay_id` is failed, it should returns a failure result that contains a `wxPayError`
    func testLaunchWeChat() {
        let request = URLRequest(url: URL(string: WXPay.default.debug_url)!)
        let expectation = self.expectation(description: "testLaunchWeChat")
        
        _ = WXPay.default.prePayRequest(with: request) { result in
            expectation.fulfill()
            
            if case .failure(let error) = result {
                print("[PayWayWeChatTests] \(error)")
                guard case .wxPayError(let response) = error, response.code == 99 else {
                    XCTFail("WXPayError.wxPayError was expected, and code should be 99")
                    return
                }
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    private let timeout: TimeInterval = 30
    private let callbackTimeout: TimeInterval = 30
}
