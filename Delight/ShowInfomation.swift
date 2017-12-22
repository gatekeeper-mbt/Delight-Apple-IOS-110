//
//  DateTimePicker.swift
//  DateTimePicker
//
//  Created by Huong Do on 9/16/16.
//  Copyright © 2016 ichigo. All rights reserved.
//

import UIKit
import CoreBluetooth

class BTServiceInfo {
    var uuid: String!
    var characteristics: String
    init(uuid: String, characteristics: String) {
        self.uuid = uuid
        self.characteristics = characteristics
    }
}

@objc public class ShowInfomation: UIView {
    // public vars
    public var myCentralManager:CBCentralManager!
    public var peripheral: CBPeripheral!
    public var deviceInformationSeriver : CBService!
    public var customTableView: UITableView!
    
    public var backgroundViewColor: UIColor? = .clear {
        didSet {
            shadowView.backgroundColor = backgroundViewColor
        }
    }
    
    public var highlightColor = UIColor(red: 0/255.0, green: 199.0/255.0, blue: 194.0/255.0, alpha: 1) {
        didSet {
            doneButton.setTitleColor(highlightColor, for: .normal)
        }
    }
    
    public var darkColor = UIColor(red: 0, green: 22.0/255.0, blue: 39.0/255.0, alpha: 1) {
        didSet {
            doneButton.setTitleColor(darkColor.withAlphaComponent(0.5), for: .normal)
        }
    }
    
    var didLayoutAtOnce = false
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !didLayoutAtOnce {
            didLayoutAtOnce = true
        } else {
            self.configureView()
        }
    }
    
    public var doneButtonTitle = NSLocalizedString("alertdialog_ok", comment: "") {
        didSet {
            doneButton.setTitle(doneButtonTitle, for: .normal)
            let size = doneButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
            doneButton.frame = CGRect(x: contentView.frame.width - size, y: 0, width: size, height: 44)
        }
    }
    
    public var completionHandler: ((Int)->Void)?
    
    // private vars
    private var contentHeight: CGFloat = 400
    
    private var shadowView: UIView!
    private var contentView: UIView!
    private var doneButton: UIButton!
    private var titleLabel: UILabel!

    var btServices: [BTServiceInfo] = []

    
    
    @objc open class func show(CentralManager: CBCentralManager, peripheral: CBPeripheral, deviceInformationSeriver : CBService) -> ShowInfomation {
        let showInfomation = ShowInfomation()
        showInfomation.myCentralManager = CentralManager
        showInfomation.peripheral = peripheral
        showInfomation.deviceInformationSeriver = deviceInformationSeriver
        
        showInfomation.configureView()
        UIApplication.shared.keyWindow?.addSubview(showInfomation)
        
        return showInfomation
    }
    
    private func configureView() {
        if self.contentView != nil {
            self.contentView.removeFromSuperview()
        }
        let screenSize = UIScreen.main.bounds.size
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: screenSize.width,
                            height: screenSize.height)
        // shadow view
        shadowView = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: frame.width,
                                          height: frame.height))
        shadowView.backgroundColor = backgroundViewColor ?? UIColor.black.withAlphaComponent(0.3)
        shadowView.alpha = 1
        let shadowViewTap = UITapGestureRecognizer(target: self, action: #selector(DateTimePicker.dismissView(sender:)))
        shadowView.addGestureRecognizer(shadowViewTap)
        addSubview(shadowView)
        
        // content view
        contentView = UIView(frame: CGRect(x: 0,
                                           y: frame.height,
                                           width: frame.width,
                                           height: contentHeight))
        contentView.layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        contentView.layer.shadowRadius = 1.5
        contentView.layer.shadowOpacity = 0.5
        contentView.backgroundColor = .white
        contentView.isHidden = true
        addSubview(contentView)
        
        // title view
        let titleView = UIView(frame: CGRect(origin: CGPoint.zero,
                                             size: CGSize(width: contentView.frame.width, height: 44)))
        titleView.backgroundColor = .white
        contentView.addSubview(titleView)
        
        titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 10, y: 0, width: 160, height: 44)
        titleLabel.text = NSLocalizedString("device_info", comment: "")
        titleLabel.textColor = UIColor.red
        titleView.addSubview(titleLabel)
        
        // done button
        doneButton = UIButton(type: .system)
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.setTitleColor(highlightColor, for: .normal)
        doneButton.addTarget(self, action: #selector(ShowInfomation.dismissView(sender:)), for: .touchUpInside)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        doneButton.isHidden = false
        let doneSize = doneButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
        doneButton.frame = CGRect(x: contentView.frame.width - doneSize, y: 0, width: doneSize, height: 44)
        titleView.addSubview(doneButton)

        //custom TableView
        customTableView = UITableView(frame: CGRect(x:0,
                                                    y: titleView.frame.height,
                                                    width: contentView.frame.width,
                                                    height: contentView.frame.height))
        customTableView.rowHeight = 36
        customTableView.showsVerticalScrollIndicator = false
        customTableView.separatorStyle = .none
        customTableView.delegate = self
        customTableView.dataSource = self
        customTableView.isHidden = false
        // register the custom tableview cell
        let nib = UINib(nibName: "InfoTableViewCell", bundle: nil)
        customTableView.register(nib, forCellReuseIdentifier: "Cell")
        contentView.addSubview(customTableView)
        
        contentView.isHidden = false
        
        // animate to show contentView
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height - self.contentHeight,
                                            width: self.frame.width,
                                            height: self.contentHeight)
        }, completion: nil)
        
        //取消，直接由控制頁取得Information
        //peripheral.delegate = self
        //peripheral.discoverCharacteristics(nil, for: deviceInformationSeriver)
    }

    
    public func dismissView(sender: UIButton?=nil) {
        UIView.animate(withDuration: 0.3, animations: {
            // animate to show contentView
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height,
                                            width: self.frame.width,
                                            height: self.contentHeight)
        }) { (completed) in
            if sender == self.doneButton {
                self.completionHandler?(1)
            }
            self.removeFromSuperview()
        }
    }
}

//--藍牙------------------------------------------
extension ShowInfomation :CBCentralManagerDelegate,CBPeripheralDelegate{
    
    
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    //掃描到 characteristic
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        if error != nil{
            print("查找 characteristics 時 \(String(describing: peripheral.name)) 報錯 \(String(describing: error?.localizedDescription))")
        }
        
        //獲取Characteristic的值，讀到數據會進入方法：
        //func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
                
        for characteristic in service.characteristics! {
            print(characteristic.uuid.uuidString)
            peripheral.readValue(for: characteristic)
        }
    }
    
    
    //獲取的charateristic的值
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        print("----didUpdateValueForCharacteristic---")
        let data:Data = characteristic.value!
        
        print(characteristic.uuid)
        let uuid = characteristic.uuid.uuidString
        
        if uuid != "2A23" && uuid != "2A28" && uuid != "2A2A" && uuid != "2A50"{
            var value:String = ""
            value = String(data: data, encoding: .utf8)!
            print(value)
            btServices.append(BTServiceInfo(uuid: characteristic.uuid.description, characteristics: value))
        }

        customTableView.reloadData()
    }

}

//--Table-----------------------------------------------------------------------
extension ShowInfomation: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return btServices.count
    }
    
    //單元格高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat {
            return 70
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:InfoTableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! InfoTableViewCell
        print(btServices[indexPath.row].uuid)
        print(btServices[indexPath.row].characteristics)
        cell.title.text = btServices[indexPath.row].uuid.description
        cell.characteristic.text = btServices[indexPath.row].characteristics
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {


    }

}

