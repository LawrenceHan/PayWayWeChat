//
//  ViewController.swift
//  example
//
//  Created by han guang on 2019/11/12.
//  Copyright © 2019 han guang. All rights reserved.
//

import UIKit
import PayWayWeChat

class ViewController: UIViewController {

    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func payClicked(_ sender: UIButton) {
        UIView.animate(withDuration: 0.33) {
            self.blurView.isHidden = false
        }
        activityIndicator.startAnimating()
        
        _ = WXPay.default.prePayRequest(with: URLRequest(url: URL(string: "https://www.baidu.com")!)) { result in
            print("received result: \(result)")
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            switch result {
            case .success(let response):
                alert.title = "WXPay success"
                alert.message = "code: \(response.code), message: \(response.message)"
            case .failure(let error):
                alert.title = "WXPay failed"
                alert.message = "\(error)"
            }
            
            UIView.animate(withDuration: 0.33, animations: {
                self.blurView.isHidden = true
            })
            self.activityIndicator.stopAnimating()
            
            alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

