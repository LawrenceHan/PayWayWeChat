//
//  WXPay.swift
//  PayWayWeChat
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//


import Foundation
import WeChatSDK

public final class WXPay: NSObject {
    
    // MARK: - Public
    
    public static let `default` = WXPay()
    public var isDebug = false
    public var callbackTimeout = 30.0
    
    public func registerApp(appId: String, universalLink: String) {
        if isDebug {
            WXApi.registerApp(debug_appId, universalLink: debug_universalLink)
        } else {
            WXApi.registerApp(appId, universalLink: universalLink)
        }
    }
    
    public func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    public func prePayRequest(with request: URLRequest, completion: @escaping (Result<WXPayResponse, WXPayError>) -> Void) -> URLSessionTask? {
        
        // clean _completion
        if _completion != nil {
            _completion = nil
            print("[PayWayWeChat] only support one wxpay request at a time, cancelled last one.")
        }
        
        // debug setup
        var request = request
        if isDebug {
            request = URLRequest(url: URL(string: debug_url)!)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // create data task
        let task = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
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
            
            // Got result from backend, open WeChat app if success
            switch result {
            case .success(let payReq):
                DispatchQueue.main.async { [unowned self] in
                    WXApi.send(payReq.payRequest) { result in
                        if result {
                            // save the completion for later WeChat callback
                            self._completion = completion
                            
                            // Setup WeChat callback timeout function
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.callbackTimeout) {
                                #if DEBUG
                                print("[PayWayWeChat] timeout callback")
                                #endif
                                self._completion?(.failure(.wxPayError(code: 100, message: "timeout (\(self.callbackTimeout)) for wx prepay request")))
                                self._completion = nil
                            }
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
    
    // MARK: - Private
    
    private var _completion: ((Result<WXPayResponse, WXPayError>) -> Void)?
    private let debug_appId = "wxb4ba3c02aa476ea1"
    private let debug_universalLink = "https://help.wechat.com/sdksample/"
    private let debug_url = "https://wxpay.wxutil.com/pub_v2/app/app_pay.php?plat=ios"
}

// MARK: - WXApi delegate
extension WXPay: WXApiDelegate {
    
    public func onReq(_ req: BaseReq) {
    }
    
    // received callback from WeChat app
    public func onResp(_ resp: BaseResp) {
        let payload = WXPayResponse(code: Int(resp.errCode), message: resp.errStr, type: Int(resp.type))
        
        // send notification out
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

// MARK: - Notification extension
public extension NSNotification.Name {
    static let newWXPayResp = NSNotification.Name("com.hanguang.paywaywechat.newWXPayResp")
}
