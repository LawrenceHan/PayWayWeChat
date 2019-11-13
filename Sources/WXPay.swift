//
//  WXPay.swift
//  PayWayWeChat
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//


import Foundation
import WeChatSDK

let _appId = "wxb4ba3c02aa476ea1"
let _universalLink = "https://help.wechat.com/sdksample/"
let _url = "https://wxpay.wxutil.com/pub_v2/app/app_pay.php?plat=ios"

public final class WXPay: NSObject {
    
    // MARK: - Public
    
    public static let `default` = WXPay()
    public var isDebug = false
    public var callbackTimeout = 30.0
    
    public func registerApp(appId: String, universalLink: String) {
        if isDebug {
            WXApi.registerApp(_appId, universalLink: _universalLink)
        } else {
            WXApi.registerApp(appId, universalLink: universalLink)
        }
    }
    
    public func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    public func prePayRequest(with request: URLRequest, completion: @escaping (Result<WXPayResponse, WXPayError>) -> Void) -> URLSessionTask? {
        if _completion != nil {
            _completion = nil
            print("[PayWayWeChat] only support one wxpay request at a time, cancelled last one.")
        }
        
        var request = request
        if isDebug {
            request = URLRequest(url: URL(string: _url)!)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
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
                DispatchQueue.main.async { [unowned self] in
                    WXApi.send(payReq.payRequest) { result in
                        if result {
                            self._completion = completion
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
}

// MARK: - WXApi delegate
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

// MARK: - Notification extension
public extension NSNotification.Name {
    static let newWXPayResp = NSNotification.Name("com.hanguang.paywaywechat.newWXPayResp")
}
