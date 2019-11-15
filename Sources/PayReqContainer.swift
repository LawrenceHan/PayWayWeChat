//
//  PayReqContainer.swift
//  PayWayWeChat
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//

import Foundation
import WeChatSDK

/// Objective-c class doesn't support `Decodable`, so we create a container class for it.
final class PayReqContainer: Decodable {
    let payRequest: PayReq
    
    init(payreq: PayReq) {
        self.payRequest = payreq
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _ = try container.decode(String.self, forKey: .appid)
        let partnerid = try container.decode(String.self, forKey: .partnerid)
        let prepayid = try container.decode(String.self, forKey: .prepayid)
        let package = try container.decode(String.self, forKey: .package)
        let noncestr = try container.decode(String.self, forKey: .noncestr)
        let timestamp = try container.decode(UInt32.self, forKey: .timestamp)
        let sign = try container.decode(String.self, forKey: .sign)
        
        let result = PayReq()
        result.partnerId = partnerid
        result.prepayId = prepayid
        result.package = package
        result.nonceStr = noncestr
        result.timeStamp = timestamp
        result.sign = sign
        payRequest = result
    }
    
    enum CodingKeys: String, CodingKey {
        case appid
        case partnerid
        case prepayid
        case package
        case noncestr
        case timestamp
        case sign
    }
}
