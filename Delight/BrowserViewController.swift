//
//  HomeVC.swift
//  AKSwiftSlideMenu
//
//  Created by MAC-186 on 4/8/16.
//  Copyright © 2016 Kode. All rights reserved.
//

import UIKit
import WebKit

class BrowserViewController: BaseViewController, WKNavigationDelegate, BrowserDelegate {
    
    var webView: WKWebView
    var URLString : String?
    var UrlAddress = UrlDetail()
    var firstStart : Bool = false
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRect.zero)
        super.init(coder: aDecoder)
        
        self.webView.navigationDelegate = self
    }
    
    deinit {
        // perform the deinitialization
        if (firstStart == true){
            webView.removeObserver(self, forKeyPath: "loading", context: nil)
            webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
            print("is dead")
        }
        
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addSlideMenuButton()
        
        self.title = "Browser"

        view.insertSubview(webView, belowSubview: progressView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: -44)
        let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        print(UrlAddress.Address)
        firstStart = true
        
        let url = URL(string:UrlAddress.Address)
        let request = URLRequest(url:url!)
        webView.load(request)
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (BaseViewController.reLoaddelegate == nil) {
            BaseViewController.reLoaddelegate = self
        }
        
        //視圖顯示完成前執行
        print("viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //視圖顯示完成執行
        print("viewDidAppear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        BaseViewController.reLoaddelegate = nil
  
        print("BrowserviewDidDisappear")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forward(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reload(_ sender: UIBarButtonItem) {
        let request = URLRequest(url:webView.url!)
        webView.load(request)
    }
    
    func toreload(URLString : String) {
        let url = URL(string:URLString)
        let request = URLRequest(url:url!)
        webView.load(request)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
        }
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
