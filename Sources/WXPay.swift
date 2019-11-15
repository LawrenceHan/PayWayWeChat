//
//  WXPay.swift
//  PayWayWeChat
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//


import Foundation
import WeChatSDK

/// A single class that handles `WeChatPay` operations.
public final class WXPay: NSObject {
    
    // MARK: - Public
    
    /// The unique result for `WeChatPay` request
    public typealias WXPayResult = Result<WXPayResponse, WXPayError>
    
    /// The default static instance.
    public static let `default` = WXPay()
    
    /// Set to true to use WeChat official testing env, default is false.
    public var isDebug = false
    
    /// The WeChat app callback timeout, default is 0 means wait forever, any value that less than 0 will be ignored.
    public var callbackTimeout: TimeInterval = 0.0
    
    /// Register your app in `application:didFinishLaunchingWithOptions`.
    public func registerApp(appId: String, universalLink: String) {
        if isDebug {
            WXApi.registerApp(debug_appId, universalLink: debug_universalLink)
        } else {
            WXApi.registerApp(appId, universalLink: universalLink)
        }
    }
    
    /// `WeChat` app callback delegate.
    public func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    /// Use this function to handle a `WeChat Pay` request,
    /// request backend to generate a payment, then use the `prepay_id` from backend
    /// to launch WeChat app.
    /// - Parameter request: A `URLRequest` instance, ideally you should create the request with your custom configurations,
    /// or using any networking framework to generate a formatted request.
    /// - Parameter completion: A closure that contains a `WXPayResult` either be success:  `WXPayResponse` or failure: `WXPayError`.
    /// The closure is guaranteed to be called, unless `WeChat` app doesn't run callback.
    /// In that case, you can given callbackTimeout a greater than 0 value, then the closure will be called when it reaches timeout.
    /// If there're 2 request is running, then only the last one's completion closure will be called.
    /// - Returns: A `URLSessionTask` instance you can use later on.
    public func prePayRequest(with request: URLRequest, completion: @escaping (WXPayResult) -> Void) -> URLSessionTask {
        
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
        
        // create a data task
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
                            if self.callbackTimeout > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + self.callbackTimeout) {
                                    #if DEBUG
                                    print("[PayWayWeChat] timeout callback")
                                    #endif
                                    self._completion?(.failure(.wxPayError(code: 100, message: "timeout (\(self.callbackTimeout)) for wx prepay request")))
                                    self._completion = nil
                                }
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
    
    // MARK: - Internal
    
    let debug_appId = "wxb4ba3c02aa476ea1"
    let debug_universalLink = "https://help.wechat.com/sdksample/"
    let debug_url = "https://wxpay.wxutil.com/pub_v2/app/app_pay.php?plat=ios"
    
    // MARK: - Private
    
    private var _completion: ((WXPayResult) -> Void)?
}

// MARK: - WXApi delegate

extension WXPay: WXApiDelegate {
    
    /// Handles `WeChat` initialed request.
    /// Not suport currently.
    public func onReq(_ req: BaseReq) {
    }
    
    /// Handles `WeChat` callbacks.
    /// Whenever received callback from WeChat app, a notification named `newWXPayResp` will be sent,
    /// if there's an ongoing pay request, then its completion closure will be called if it is non nil.
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
    /// Notification for received `WeChat` callback, the object is `WXPayResponse`.
    static let newWXPayResp = NSNotification.Name("com.hanguang.paywaywechat.newWXPayResp")
}
