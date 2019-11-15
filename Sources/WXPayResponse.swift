//
//  WXPayResponse.swift
//  example
//
//  Created by han guang on 2019/11/13.
//  Copyright © 2019 han guang. All rights reserved.
//

import Foundation

/// `WeChat` payment callback response wrapper
public struct WXPayResponse {
    
    /// A unique identifier you can use for diff
    public var id: String {
        return "WXPayResponse-\(code)" + message + "\(type)"
    }
    
    /// Result code. -2 = cancelled, -1 = common error, 0 = success.
    public let code: Int
    
    /// Result error message, can be empty.
    public let message: String
    
    /// Result type.
    public let type: Int
}
