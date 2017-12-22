//
//  BaseViewController.swift
//  AKSwiftSlideMenu
//
//  Created by Ashish on 21/09/15.
//  Copyright (c) 2015 Kode. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, SlideMenuDelegate {
    var URLAddress = UrlDetail()
    var TagClose:Bool = false
    var shadowView: UIView!
   
    weak static var reLoaddelegate : BrowserDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //透過viewController之間連線的segue
        print(segue.identifier!)
        if(segue.identifier == "goBrowser"){
            let controller = segue.destination as! BrowserViewController
            controller.UrlAddress = URLAddress
        }else if(segue.identifier == "goBluetooth"){
            print(sender!);
            let controller = segue.destination as! BluetoothViewController
            controller.peripheral = sender as! CBPeripheral
            //controller.myDeviceData = [sender as! ScanDeviceDATA]
        }
    }
    
    func ToRootViewController(){
        
    }
    
    func slideMenuItemSelectedAtIndex(_ index: Int32) {
        let topViewController : UIViewController = self.navigationController!.topViewController!
        print("View Controller is : \(topViewController) \n", terminator: "")

        switch(index){
        case 0:
            print("Home\n", terminator: "")

            //返回RootView
            self.navigationController?.popToRootViewController(animated: true)

            break
        case 1:
            print("BrowserView\n", terminator: "")
            URLAddress.Address = "http://www.mathbright.com.tw"
            if (BaseViewController.reLoaddelegate != nil) {
                BaseViewController.reLoaddelegate?.toreload(URLString: URLAddress.Address)
            }else{
                //透過viewController之間連線的segue
                self.performSegue(withIdentifier: "goBrowser", sender: 0)
            }
            self.openViewControllerBasedOnIdentifier("BrowserView")
            break
        case 2:
            print("BrowserView\n", terminator: "")
            /*URLAddress.Address = "http://www.mathbright.com.tw/contact.html"
             if (BaseViewController.reLoaddelegate != nil) {
                BaseViewController.reLoaddelegate?.toreload(URLString: URLAddress.Address)
             }else{
                //透過viewController之間連線的segue
                self.performSegue(withIdentifier: "goBrowser", sender: 0)
             }
             self.openViewControllerBasedOnIdentifier("BrowserView")
            */
            let email = "info@mathbright.com.tw"
            UIApplication.shared.openURL(NSURL(string: "mailto://\(email)")! as URL)

            break
        case 3:
            print("AboutVC\n", terminator: "")
            self.openViewControllerBasedOnIdentifier("AboutVC")
            break
            
        default:
            print("default\n", terminator: "")
            
        }

    }

    func openViewControllerBasedOnIdentifier(_ strIdentifier:String){
        let destViewController : UIViewController = self.storyboard!.instantiateViewController(withIdentifier: strIdentifier)
        
        let topViewController : UIViewController = self.navigationController!.topViewController!
        
        if (topViewController.restorationIdentifier! == destViewController.restorationIdentifier!){
            print("Same VC")
        } else {
            self.navigationController!.pushViewController(destViewController, animated: true)
        }
    }
    
    func addSlideMenuButton(){
        let btnShowMenu = UIButton(type: UIButtonType.system)
        btnShowMenu.setImage(self.defaultMenuImage(), for: UIControlState())
        btnShowMenu.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnShowMenu.addTarget(self, action: #selector(BaseViewController.onSlideMenuButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        let customBarItem = UIBarButtonItem(customView: btnShowMenu)
        self.navigationItem.rightBarButtonItem = customBarItem;
    }

    func defaultMenuImage() -> UIImage {
        var defaultMenuImage = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 30, height: 22), false, 0.0)
        
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 3, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 10, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 17, width: 30, height: 1)).fill()
        
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 4, width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 11,  width: 30, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 18, width: 30, height: 1)).fill()
        
        defaultMenuImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
       
        return defaultMenuImage;
    }
    
    func circleImage() -> UIImage {
        var circleFavicon = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 30, height: 30), false, 0.0)
        
        //取得目前的上下文，這裏得到的就是上面剛建立的圖片上下文
        let context = UIGraphicsGetCurrentContext()
        
        //劃邊框（大圓）
        //borderColor.set()
        UIColor.blue.set()
        let bigRadius: CGFloat = 26 * 0.5 //大圓半径
        let centerX = bigRadius //圓心
        let centerY = bigRadius //圓心
        let center = CGPoint.init(x: centerX + 2, y: centerY + 2)
        let endAngle = CGFloat(Double.pi*2)
        context?.addArc(center: center, radius: bigRadius, startAngle: 0, endAngle: endAngle, clockwise: false)
        context?.strokePath()
        
        //畫i
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(x: 14, y: 8, width: 1, height: 2)).fill()
        UIBezierPath(rect: CGRect(x: 14, y: 12, width: 1, height: 10)).fill()

        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 15, y: 8, width: 1, height: 2)).fill()
        UIBezierPath(rect: CGRect(x: 15, y: 12,  width: 1, height: 10)).fill()

        //取圖
        circleFavicon = UIGraphicsGetImageFromCurrentImageContext()!
        
        //结束上下文
        UIGraphicsEndImageContext()

        
        return circleFavicon;
    }
    
    public var backgroundViewColor: UIColor? = .clear
    
    @objc func onSlideMenuButtonPressed(_ sender : UIButton){
        print("onSlideMenuButtonPressed")
        if (sender.tag == 10 && TagClose == false)
        {
            sender.tag = 0;
            
            closeMenu()
            
            return
        }else if TagClose == true{
            TagClose = false
        }
        
        var MenuHeight : CGFloat = 64
        
        let destViewController : UIViewController = self.storyboard!.instantiateViewController(withIdentifier: "BrowserView")
        
        let topViewController : UIViewController = self.navigationController!.topViewController!
        
        if (topViewController.restorationIdentifier! == destViewController.restorationIdentifier!){
            MenuHeight = 0
        }
        
        MenuViewController.MenuHeight.Height = MenuHeight
        
        sender.isEnabled = false
        sender.tag = 10
        
        // 向右滑動關閉ＭＥＮＵ
        let swipeRight = UISwipeGestureRecognizer(
            target:self,
            action:#selector(BaseViewController.swipe))
        swipeRight.direction = .right
        
        // 為視圖加入監聽手勢
        self.view.addGestureRecognizer(swipeRight)
        
        //加入點擊空白處關閉ＭＥＮＵ
        let screenSize = UIScreen.main.bounds.size
        // shadow view
        shadowView = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: screenSize.width,
                                          height: screenSize.height))
        shadowView.backgroundColor = backgroundViewColor ?? UIColor.black.withAlphaComponent(0.3)
        shadowView.alpha = 1
        let shadowViewTap = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.closeMenu))
        shadowView.addGestureRecognizer(shadowViewTap)
        self.view.addSubview(shadowView)
        
        let menuVC : MenuViewController = self.storyboard!.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        menuVC.btnMenu = sender
        menuVC.delegate = self
        self.view.addSubview(menuVC.view)
        self.addChildViewController(menuVC)
        
        menuVC.view.layoutIfNeeded()        
        menuVC.view.frame=CGRect(x: UIScreen.main.bounds.size.width, y: MenuHeight, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            menuVC.view.frame=CGRect(x: 60, y: MenuHeight, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height);
            sender.isEnabled = true
            }, completion:nil)
    }
    
    func closeMenu(){
        // To Hide Menu If it already there
        self.slideMenuItemSelectedAtIndex(-1);
        
        TagClose = true
        let viewMenuBack : UIView = view.subviews.last!
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            var frameMenu : CGRect = viewMenuBack.frame
            frameMenu.origin.x = UIScreen.main.bounds.size.width
            viewMenuBack.frame = frameMenu
            viewMenuBack.layoutIfNeeded()
            viewMenuBack.backgroundColor = UIColor.clear
        }, completion: { (finished) -> Void in
            viewMenuBack.removeFromSuperview()
            self.shadowView.removeFromSuperview()
        })
    }
    
    // 觸發滑動手勢後 執行的動作
    func swipe(recognizer:UISwipeGestureRecognizer) {
        
        if recognizer.direction == .right {
            print("Go Right")
            closeMenu()
        }
    }
}
