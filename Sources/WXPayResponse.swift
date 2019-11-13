//
//  WXPayResponse.swift
//  example
//
//  Created by han guang on 2019/11/13.
//  Copyright © 2019 han guang. All rights reserved.
//

import Foundation

public struct WXPayResponse {
    public var id: String {
        return "WXPayResponse-\(code)" + message + "\(type)"
    }
    
    public let code: Int
    public let message: String
    public let type: Int
}
