//
//  WXPay.swift
//  PayWayWeChat
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//


import Foundation
import PayWayWeChatPrivate

let _appId = "wxb4ba3c02aa476ea1"
let _universalLink = "https://help.wechat.com/sdksample/"
let url = "https://wxpay.wxutil.com/pub_v2/app/app_pay.php?plat=ios"

public final class WXPay: NSObject {
    
    public static let `default` = WXPay()
    
    public func registerApp(appId: String, universalLink: String) {
        WXApi.registerApp(_appId, universalLink: _universalLink)
    }
    
    public func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    public func prePayRequest(with productId: Int, completion: @escaping (Result<WXPayResponse, WXPayError>) -> Void) -> URLSessionTask? {
        if _completion != nil {
            _completion?(.failure(.wxPayError(code: 99, message: "only support one wxpay request at a time, cancelled last one.")))
            _completion = nil
        }
        
        let error = RequestError.invalidURL(url)
        guard let url = URL(string: url) else {
            completion(.failure(.requestError(error)))
            return nil
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            let result: Result<PayReqContainer, WXPayError>
            
            switch (data, urlResponse, error) {
            case (_, _, let error?):
                result = .failure(.connectionError(error))
                
            case (let data?, let urlResponse as HTTPURLResponse, _):
                if 200..<300 ~= urlResponse.statusCode {
                    do {
                        result = .success(try JSONDecoder().decode(PayReqContainer.self, from: data))
                    } catch {
                        result = .failure(.responseError(error))
                    }
                } else {
                    completion(.failure(.responseError(ResponseError.unacceptableStatusCode(urlResponse.statusCode))))
                    return
                }
                
            default:
                result = .failure(.responseError(ResponseError.nonHTTPURLResponse(urlResponse)))
            }
            
            switch result {
            case .success(let payReq):
                DispatchQueue.main.async { [weak self] in
                    WXApi.send(payReq.payRequest) { result in
                        if result {
                            self?._completion = completion
                        } else {
                            completion(.failure(.wxPayError(code: 99, message: "WXApi.send(payReq.payRequest) failed")))
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    private var _completion: ((Result<WXPayResponse, WXPayError>) -> Void)?
}

extension WXPay: WXApiDelegate {
    
    public func onReq(_ req: BaseReq) {
    }
    
    public func onResp(_ resp: BaseResp) {
        let payload = WXPayResponse(code: Int(resp.errCode), message: resp.errStr, type: Int(resp.type))
        NotificationCenter.default.post(name: .newWXPayResp, object: payload)
        
        let result: Result<WXPayResponse, WXPayError>
        
        switch resp.errCode {
        case WXSuccess.rawValue:
            result = .success(payload)
        default:
            result = .failure(.wxPayError(code: Int(resp.errCode), message: resp.errStr))
        }
        
        _completion?(result)
        _completion = nil
    }
}

public struct WXPayResponse {
    public var id: String {
        return "WXPayResponse-\(code)" + message + "\(type)"
    }
    
    public let code: Int
    public let message: String
    public let type: Int
}

public extension NSNotification.Name {
    static let newWXPayResp = NSNotification.Name("com.hanguang.paywaywechat.newWXPayResp")
}

/// `WXPayError` represents an error that occurs while task for a wxpay request.
public enum WXPayError: Error {
    /// Error of `WXPay callback`
    case wxPayError(code: Int, message: String)
    
    /// Error of `URLSession`.
    case connectionError(Error)
    
    /// Error while creating `URLRequest` from `Request`.
    case requestError(Error)
    
    /// Error while creating `Request.Response` from `(Data, URLResponse)`.
    case responseError(Error)
}

/// `RequestError` represents a common error that occurs while building `URLRequest` from `Request`.
public enum RequestError: Error {
    /// Indicates `url` string is invalid.
    case invalidURL(String)
    
    /// Indicates `URLRequest` is invalid.
    case invalidURLRequest(URLRequest)
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
