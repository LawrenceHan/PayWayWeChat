//
//  Error.swift
//  example
//
//  Created by han guang on 2019/11/13.
//  Copyright © 2019 han guang. All rights reserved.
//

import Foundation

/// `WXPayError` represents an error that occurs while task for a wxpay request.
public enum WXPayError: Error {
    /// Error of `WXPay request`
    /// - Parameter code: -2 = user cancelled, -1 = common error, 0 = success,
    /// 99 = launch WeChat app failed, 100 = wait for WeChat app callback timeout
    case wxPayError(code: Int, message: String)
    
    /// Error of `URLSession`.
    case connectionError(Error)
    
    /// Error while creating `URLRequest` from `Request`.
    case requestError(Error)
    
    /// Error while creating `Request.Response` from `(Data, URLResponse)`.
    case responseError(Error)
}

/// `ResponseError` represents a common error that occurs while getting `Request.Response`
/// from raw result tuple `(Data?, URLResponse?, Error?)`.
public enum ResponseError: Error {
    /// Indicates the session adapter returned `URLResponse` that fails to down-cast to `HTTPURLResponse`.
    case nonHTTPURLResponse(URLResponse?)
    
    /// Indicates `HTTPURLResponse.statusCode` is not acceptable.
    /// In most cases, *acceptable* means the value is in `200..<300`.
    case unacceptableStatusCode(Int)
    
    /// Indicates `Any` that represents the response is unexpected.
    case unexpectedObject(Any)
}
