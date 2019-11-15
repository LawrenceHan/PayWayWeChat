//
//  Error.swift
//  example
//
//  Created by han guang on 2019/11/13.
//  Copyright © 2019 han guang. All rights reserved.
//

import Foundation

/// `WXPayError` represents errors that occurs for the whole operation.
public enum WXPayError: Error {
    /// Errors of `WeChatSDK`
    /// - Parameter code: -2 = user cancelled, -1 = common error, 0 = success,
    /// 99 = launch WeChat app failed, 100 = wait for WeChat app callback timeout.
    case wxPayError(code: Int, message: String)
    
    /// Errors of `URLSession`. For example: timeout, task cancelled and etcs.
    case connectionError(Error)

    /// Errors while trying to parse `HTTPURLResponse`. For details check `ResponseError`.
    case responseError(Error)
}

/// `ResponseError` represents a common error that occurs while trying to parse `HTTPURLResponse`
/// from raw result tuple `(Data?, URLResponse?, Error?)`.
public enum ResponseError: Error {
    /// Indicates the session returned `URLResponse` that fails to down-cast to `HTTPURLResponse`.
    case nonHTTPURLResponse(URLResponse?)
    
    /// Indicates `HTTPURLResponse.statusCode` is not acceptable.
    /// In most cases, *acceptable* means the value is in `200..<300`.
    case unacceptableStatusCode(Int)
    
    /// Indicates `Any` that represents the response is unexpected.
    case unexpectedObject(Any)
}
