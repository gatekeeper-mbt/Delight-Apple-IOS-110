//
//  Utilities.swift
//  Delight
//
//  Created by mac on 2017/7/15.
//  Copyright © 2017年 mac. All rights reserved.
//

import Foundation
import UIKit

//結構體
struct UrlDetail{
    var Address: String!
}

struct NaviHeight{
    var Height : CGFloat!
}

struct ScanDeviceDATA {
    var Name:String!
    var devicePeripheral:CBPeripheral!
    var Address:String!
}

struct DeviceDATA {
    var devicePeripheral:CBPeripheral!
}

struct CentralManager{
    var  CentralManager:CBCentralManager!
}

protocol SlideMenuDelegate : class {
    func slideMenuItemSelectedAtIndex(_ index : Int32)
}

protocol BrowserDelegate : class {
    func toreload(URLString : String)
}

class deviceSave{
    
    func save(address: String,  str: NSData){
        //儲存在記事本
        let preferencesSave = UserDefaults.standard
        
        preferencesSave.setValue(str, forKey: address) //儲存字串

        preferencesSave.synchronize()
    }
    
    func read(address: String) -> NSData?{
        //讀取記事本
        let preferencesRead = UserDefaults.standard
        
        if preferencesRead.object(forKey: address) == nil {
            //  Doesn't exist
            NSLog("NO name", "...")
            return nil
        } else {

            //let name = preferencesRead.string(forKey: address) //讀取字串
            let name = preferencesRead.data(forKey: address) //讀取字串
            
            //NSLog("name:\(name!)", "")
            
            return name! as NSData
        }
    }
    
    func del(address: String){
        let preferencesDel = UserDefaults.standard
        preferencesDel.removeObject(forKey: address)
    }
    
}

struct Devicelist {
    var device = ["deviceName": "A", "deviceAddress": "B", "time": "C"]
}
