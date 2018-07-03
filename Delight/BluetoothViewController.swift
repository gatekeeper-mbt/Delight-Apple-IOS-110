//
//  BluetoothControlView.swift
//  Delight
//
//  Created by mac on 2017/8/9.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothViewController: BaseViewController{
    @IBOutlet weak var TimePicker: UIButton!
    @IBOutlet weak var TimeView: UIView!
    @IBOutlet weak var setTimer: UIButton!
    
    @IBOutlet weak var minImage: UIImageView!
    @IBOutlet weak var maxImage: UIImageView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var hourglassButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var colonLable1: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var colonLable2: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    
    //系统藍牙管理隊象
    var myCentralManager:CBCentralManager!
    var peripheral: CBPeripheral!

    //連接的外圍設備
    var connectedPeripheral : CBPeripheral!
    //保存的設備特性
    var savedCharacteristic : CBCharacteristic!
    var writeCharacteristic:CBCharacteristic!
    var deviceCortrolSeriver : CBService!
    var deviceInformationSeriver : CBService!
    
    let deviceSaveInfo = deviceSave()
    var ConnectMACAddress:String = ""
    var DeviceName:String = ""
    
    var FirstLaunch:Bool = false
    var PowerON_Flag:Bool = false
    var hourglassON_Flag:Bool = false
    var playON_Flag:Bool = false
    var stopON_Flag:Bool = false
    var DelDevice:Bool = false
    var WriteData_Flag:Bool = false
    var mSend_INTENSITY:Bool = false
    var alertController:UIAlertController? = nil
    
    //需要連接的 CBCharacteristic 的 UUID
    let ServiceUUID =  "CBBB"
    let InformationServiceUUID =  "180A"
    let CharacteristicUUID =  "CBB1"
    
    var btServices: [BTServiceInfo] = []

    //發送獲取數據的指令
    var getbytes :[UInt8] = [0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00] //[0] Function; [1] LAMP ON/OFF; [2] INTENSITY; [3] Timer; [4] Time1; [5] Time2
    var recbytes :[UInt8] = [0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00]
    var timebytes:[UInt8] = [0x00, 0x00, 0x00]
    
    var memTime = 0
    var defaultTime = 1800
    var rediscoverServicesNum = 0
 
    var lastString : NSString!
    var sendString : NSString!
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.addSlideMenuButton()

        //讀取存擋
        let device = deviceSaveInfo.read(address: ConnectMACAddress)

        if device != nil {
            //  json 轉字典
            let dL1 = try! JSONSerialization.jsonObject(with:device! as Data, options: .mutableContainers) as! NSDictionary
            let time:String = dL1.value(forKey: "time")! as! String
            defaultTime = Int(time)!
            DeviceName = (dL1.value(forKey: "deviceName")! as! String)
        }
        
        self.navigationItem.title = DeviceName //導航列標題
        let btn1 =  UIBarButtonItem(barButtonSystemItem:.trash,
                                    target:self, action:#selector(BluetoothViewController.delDevice));
        let btn2 =  UIBarButtonItem(barButtonSystemItem:.compose,
                                    target:self, action:#selector(BluetoothViewController.reName));
        
        let btnInfo = UIButton(type: UIButtonType.system)
        btnInfo.setImage(self.circleImage(), for: .normal)
        btnInfo.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnInfo.addTarget(
            self,
            action: #selector(self.showInfomation),
            for: UIControlEvents.touchUpInside
        )
        let InfoBarItem = UIBarButtonItem(customView: btnInfo)

        let btnShowMenu = UIButton(type: UIButtonType.system)
        btnShowMenu.setImage(self.defaultMenuImage(), for: UIControlState())
        btnShowMenu.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnShowMenu.addTarget(self, action: #selector(BaseViewController.onSlideMenuButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        //let customBarItem = UIBarButtonItem(customView: btnShowMenu)

        //self.navigationItem.rightBarButtonItems = [customBarItem, InfoBarItem, btn2, btn1]
        self.navigationItem.rightBarButtonItems = [InfoBarItem, btn2, btn1]
        
        setTimer.addTarget(
            self,
            action: #selector(showTimePicker),
            for: .touchUpInside
        )
        
        //設置按钮的點擊事件
        powerButton.addTarget(
            self,
            action: #selector(PowerStatus),
            for: UIControlEvents.touchUpInside
        )
        
        //滑塊值改變響應
        slider.isContinuous = false
        slider.addTarget(
            self,
            action: #selector(sliderDidChange),
            for: UIControlEvents.valueChanged
        )
        
        hourglassButton.addTarget(
            self,
            action: #selector(hourglassStatus),
            for: UIControlEvents.touchUpInside
        )
        
        playButton.addTarget(
            self,
            action: #selector(playStatus),
            for: UIControlEvents.touchUpInside
        )
        
        stopButton.addTarget(
            self,
            action: #selector(stopStatus),
            for: UIControlEvents.touchUpInside
        )
        
        FirstLaunch = true
        hourglassButton.isEnabled = false
        powerButton.isEnabled = false
        colonLable1.isEnabled = false
        minuteLabel.isEnabled = false
        colonLable2.isEnabled = false
        secondLabel.isEnabled = false
        hoursLabel.isEnabled = false
        playButton.isEnabled = false
        stopButton.isEnabled = false
        setTimer.isEnabled = false
        slider.isEnabled = false
        minImage.alpha = 0.3
        maxImage.alpha = 0.3

        self.formateTimer(timers: defaultTime)
        memTime = defaultTime
    }
    
    func PowerStatus(){
        var value = 0.0
        if PowerON_Flag == true{
            PowerOff()
        }else{
            PowerOn()
            value = 100.0
            BTWriteValue()
        }
        
        //置滑塊的值，同时有動畫
        slider.setValue(Float(value), animated: true)
    }
    
    func PowerOn(){
        // 設置背景圖片
        powerButton.setBackgroundImage(UIImage(named: "power_on"), for: .normal)
        PowerON_Flag = true
        getbytes[1] = 0x00
        //getbytes[2] = 0xFF
        slider.isEnabled = true
        minImage.alpha = 1
        maxImage.alpha = 1
        hourglassButton.isEnabled = true
    }
    
    func PowerOff(){
        // 設置背景圖片
        powerButton.setBackgroundImage(UIImage(named: "power_off"), for: .normal)
        PowerON_Flag = false
        slider.isEnabled = false
        minImage.alpha = 0.3
        maxImage.alpha = 0.3
        hourglassButton.isEnabled = false
        hourglassON_Flag = false
        getbytes[1] = 0x01
        getbytes[2] = 0x00
       hourglassOff()
    }
    
    func hourglassStatus(){
        if hourglassON_Flag == true{
            hourglassOff()
        }else{
            hourglassOn()
        }
    }
    
    func hourglassOn(){
        // 設置背景圖片
        hourglassButton.setBackgroundImage(UIImage(named: "hourglass_on"), for: .normal)
        hourglassON_Flag = true
        playButton.isEnabled = true
        stopButton.isEnabled = true
        hoursLabel.isEnabled = true
        colonLable1.isEnabled = true
        minuteLabel.isEnabled = true
        colonLable2.isEnabled = true
        secondLabel.isEnabled = true
        setTimer.isEnabled = true
    }
    
    func hourglassOff(){
        // 設置背景圖片
        hourglassButton.setBackgroundImage(UIImage(named: "hourglass"), for: .normal)
        hourglassON_Flag = false
        playButton.isEnabled = false
        stopButton.isEnabled = false
        hoursLabel.isEnabled = false
        colonLable1.isEnabled = false
        minuteLabel.isEnabled = false
        colonLable2.isEnabled = false
        secondLabel.isEnabled = false
        setTimer.isEnabled = false

        //if playON_Flag == true{
            stopStatus()
        //}
    }
    
    func playStatus(){
        if playON_Flag == true{
            playOff()
        }else{
            playOn()
        }

        BTWriteValue()
    }
    
    func playOn(){  //開始計時
        // 設置背景圖片
        playButton.setBackgroundImage(UIImage(named: "pause_on"), for: .normal)
        stopButton.setBackgroundImage(UIImage(named: "stop_on"), for: .normal)
        playON_Flag = true
        setTimer.isEnabled = false
        getbytes[3] = 0x01
        getbytes[4] = timebytes[0]
        getbytes[5] = timebytes[1]
        getbytes[6] = timebytes[2]
    }
    
    func playOff(){ //暫停計時
        // 設置背景圖片
        playButton.setBackgroundImage(UIImage(named: "play_on"), for: .normal)
        playON_Flag = false
        getbytes[3] = 0x02
    }
    
    func stopStatus(){
        // 設置背景圖片
        playButton.setBackgroundImage( UIImage(named: "play"), for: .normal)
        stopButton.setBackgroundImage(UIImage(named: "stop_off"), for: .normal)
        playON_Flag = false
        setTimer.isEnabled = true
        getbytes[3] = 0x03

        formateTimer(timers: memTime)

        BTWriteValue()
        
    }
    
    func sliderDidChange(){
        //print(slider.value)
        var value = Int(slider.value)
        value = Int(Double(value) * 2.55)
        getbytes[2] = UInt8(value)
        print(getbytes[2])
        mSend_INTENSITY = true;
        
        BTWriteValue()
    }
    
    func BTWriteValue(){
        getbytes[0] = 0x01
        print("寫入: \(getbytes)")
        self.characteristicWriteValue(self.connectedPeripheral , didWriteValueFor :self.writeCharacteristic, value: getbytes)
        WriteData_Flag = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //視圖顯示完成前執行
        print("Bluetooth viewWillAppear")
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false;   //禁用側滑手勢
        //連接藍牙
        myCentralManager.delegate = self
        peripheral.delegate = self
        //藍牙初始
        myCentralManager.connect(peripheral, options: nil)
        print("連接藍牙")
        let message_connect = NSLocalizedString("alert_message_connect", comment: "") //連接裝置
        
        alertController = UIAlertController.init(title: "\(message_connect) \(DeviceName) ", message: nil, preferredStyle: .alert)
        self.present(alertController!, animated: true)  //開啟提醒視窗
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //視圖消失前執行
        print("Bluetooth viewWillDisappear")
        if DelDevice == false {
            //儲存資訊
            var dic = Devicelist()
            dic.device.updateValue(DeviceName, forKey: "deviceName")
            dic.device.updateValue(ConnectMACAddress, forKey: "deviceAddress")
            dic.device.updateValue(String(memTime), forKey: "time")
            
            if (JSONSerialization.isValidJSONObject(dic.device)){
                let jsonData:NSData = try! JSONSerialization.data(withJSONObject: dic.device, options: .prettyPrinted) as NSData
                deviceSaveInfo.save(address: ConnectMACAddress, str: jsonData)
            }
        }
    }
    
    func reName(){
        let rename_title = NSLocalizedString("alertdialog_rename_title", comment: "")
        let rename_meggage = NSLocalizedString("alertdialog_rename_meggage", comment: "")
        let rename_ok = NSLocalizedString("alertdialog_ok", comment: "")
        let rename_cancel = NSLocalizedString("alertdialog_cancel", comment: "")

        let alertController = UIAlertController(title: rename_title,
                                                message: rename_meggage, preferredStyle: .alert)
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = self.DeviceName
        }
        
        let cancelAction = UIAlertAction(title: rename_ok, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: rename_cancel, style: .default, handler: {
            action in
            //也可以用下標的形式獲取textField let Name = alertController.textFields![0]
            let Name = alertController.textFields!.first!
            if Name.text != "" {
                self.DeviceName = Name.text!
                print("DeviceName：\(self.DeviceName) ")
                self.navigationItem.title = self.DeviceName //導航列標題
            }
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func delDevice(){
        DelDevice = true
        deviceSaveInfo.del(address: ConnectMACAddress)
        ToRootViewController()
    }
    
    override func ToRootViewController(){
        //返回RootView
        self.navigationController?.popToRootViewController(animated: true)      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        print("BlueControllerViewDidDisappear")
    }
    
    func showTimePicker() {
        let picker = DateTimePicker.show()
        picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
        picker.darkColor = UIColor.darkGray
        //picker.doneButtonTitle = NSLocalizedString("alertdialog_ok", comment: "")
        picker.setTimer = defaultTime
        picker.completionHandler = { time in
            print(time)
            self.formateTimer(timers: time)
            self.memTime = Int(time)
            self.defaultTime = self.memTime
        }
    }
    
    func showInfomation(){
        if deviceInformationSeriver != nil {
            let picker = ShowInfomation.show(CentralManager: myCentralManager, peripheral: peripheral, deviceInformationSeriver : deviceInformationSeriver)
            picker.btServices = btServices
        
            picker.completionHandler = { num in
                print(num)
                self.peripheral.delegate = self
            }
        }
    }
    
}

//--藍牙------------------------------------------
extension BluetoothViewController :CBCentralManagerDelegate,CBPeripheralDelegate{

    
    @available(iOS 5.0, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    //連接上
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        print("--didConnect peripheral--")
        peripheral.delegate = self
        //外圍設備尋找service
        peripheral.discoverServices(nil)
        connectedPeripheral = peripheral
       
        let connect = NSLocalizedString("alert_message_bluetooth_connect", comment: "") //已連接
        let service_discovering = NSLocalizedString("progress_message_service_discovering", comment: "") //尋找服務中. 請稍候
        self.alertController?.title = "\(DeviceName) \(connect)"

        //兩秒鐘後自動消失
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self,
                                              selector: #selector(self.rediscoverServices), userInfo: nil, repeats: true)
            self.alertController?.title = service_discovering
            
        }
        
    }
    
    func rediscoverServices(){
        if rediscoverServicesNum < 3{
            connectedPeripheral.discoverServices(nil)
            rediscoverServicesNum += 1
            print(connectedPeripheral)
            print("重新掃描服務")
        }else{
            timer.invalidate()
            timer = nil
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            let service_undiscovered = NSLocalizedString("alert_message_service_undiscovered", comment: "")
            let alertController = UIAlertController.init(title: "\(DeviceName) \(service_undiscovered)", message: nil, preferredStyle: .alert)
            self.present(alertController, animated: true)  //開啟提醒視窗
            //兩秒鐘後自動消失
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                //返回RootView
                self.navigationController?.popToRootViewController(animated: true)
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
            
        }
    }
    
    //連接到Peripherals-失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        print("--didFailToConnectPeripheral--")
        print("連接到名字為 \(String(describing: peripheral.name)) 的設備失敗，原因是 \(String(describing: error?.localizedDescription))")
        
        let message_sorry = NSLocalizedString("alert_message_sorry", comment: "")
        let message_reconnection = NSLocalizedString("alert_message_reconnection", comment: "") //連接已終止，請重新連接裝置
        let cancel = NSLocalizedString("alertdialog_cancel", comment: "")
        let reconnection = NSLocalizedString("alertdialog_reconnection", comment: "") //重新連接
        
        let alertController = UIAlertController.init(title: message_sorry, message: "\(DeviceName) \(message_reconnection)", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: cancel, style: .cancel, handler: {
            action in
            self.navigationController?.popToRootViewController(animated: true)
        })
        let okAction = UIAlertAction(title: reconnection, style: .default, handler: {
            action in
            self.myCentralManager.connect(peripheral, options: nil)
            print("連接藍牙")
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)  //開啟提醒視窗
    }
    
    ///斷開
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        
        switch (central.state) {
        case .poweredOn:
            print("藍牙已開啟, 請掃描外部設備!");
            break;
        case .poweredOff:
            print("藍牙關閉，請先打開藍牙");
        default:
            break;
        }
        
        let error:String = (error?.localizedDescription)!
        print("連接到名字為 \(DeviceName) 的設備斷開，原因是\(error)")
        let message_sorry = NSLocalizedString("alert_message_sorry", comment: "")
        let message_reconnection = NSLocalizedString("alert_message_reconnection", comment: "")
        
        let alertView = UIAlertController.init(title: message_sorry, message: "\(DeviceName) \(message_reconnection)", preferredStyle: UIAlertControllerStyle.alert)
        self.present(alertView, animated: true)  //開啟提醒視窗
        //兩秒鐘後自動消失
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            //返回RootView
            self.navigationController?.popToRootViewController(animated: true)
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    //掃描到Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        print("----didDiscoverServices---")
       
        if (error != nil){
            print("查找 services 時 \(String(describing: peripheral.name)) 報錯 \(String(describing: error?.localizedDescription))")
        }
        
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        
        for service in peripheral.services! {
            print(service.uuid.uuidString)
            //需要连接的 CBCharacteristic 的 UUID
            if service.uuid.uuidString == ServiceUUID{
                peripheral.discoverCharacteristics(nil, for: service)
            }
            //紀錄device information
            if service.uuid.uuidString == InformationServiceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
                deviceInformationSeriver = service
            }
        }
        
    }
    
    
    //掃描到 characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        print("----didDiscoverCharacteristicsFor service---")
        if error != nil{
            print("查找 characteristics 時 \(String(describing: peripheral.name)) 報錯 \(String(describing: error?.localizedDescription))")
        }
        
        //獲取Characteristic的值，讀到數據會進入方法：
        //func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
        
        for characteristic in service.characteristics! {
            if characteristic.uuid.uuidString == CharacteristicUUID{
                print("characteristics: \(String(describing: characteristic.uuid.uuidString))")
                self.writeCharacteristic = characteristic
            }else if service.uuid.uuidString == InformationServiceUUID{
                let uuid = characteristic.uuid.uuidString
                if uuid != "2A23" && uuid != "2A28" && uuid != "2A2A" && uuid != "2A50"{
                    peripheral.readValue(for: characteristic)
                    print("characteristics: \(String(describing: characteristic.uuid.uuidString))")
                }
            }
        }
        
        //先讀完Information 再讀CBB1
        if writeCharacteristic != nil {
            peripheral.readValue(for: writeCharacteristic)
            //設置 characteristic 的 notifying 屬性為 true ， 表示接受廣播
            peripheral.setNotifyValue(true, for: writeCharacteristic)
            
        }
    }
    
    
    //獲取的charateristic的值
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        print("----didUpdateValueForCharacteristic---")
        
        let data:Data = characteristic.value!
        if characteristic.uuid.uuidString == CharacteristicUUID {
            recbytes  = Array(UnsafeBufferPointer(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count))
        }
        //print(data)
        //print(characteristic.uuid)
        print(recbytes)
        
       
        if recbytes.count > 4 && characteristic.uuid.uuidString == CharacteristicUUID {
            //尋找服務視窗3秒鐘後自動消失
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }

            powerButton.isEnabled = true
            
            let value = Float(recbytes[2]) / 2.55
            if mSend_INTENSITY == false{
                //設置滑塊的值，同时有動畫
                slider.setValue(Float(value), animated: true)
                getbytes[2] = recbytes[2]
            }else if Float(getbytes[2]) == value{
                mSend_INTENSITY = false
            }
            
            if recbytes[0] == 10{
                slider.isEnabled = false
                hourglassButton.isEnabled = false
            }else if recbytes[0] == 1 && PowerON_Flag == true{
                slider.isEnabled = true
                hourglassButton.isEnabled = true
            }
            
            if recbytes[1] == 0 && getbytes[1] == 0 && PowerON_Flag == false {
                PowerON_Flag = true
                PowerOn()
            }else if recbytes[1] == 1 && PowerON_Flag == true {
                PowerON_Flag = false
                //PowerOff()
                print("PowerOff~")
            }
 
            if hourglassON_Flag == false && PowerON_Flag == true && FirstLaunch == true {
                //開始
                if recbytes[3] == 1{
                    hourglassON_Flag = true
                    playON_Flag = true
                    hourglassOn()
                    playOn()
                }//暫停
                else if recbytes[3] == 2 && playON_Flag == false {
                    hourglassON_Flag = true
                    playON_Flag = true
                    hourglassOn()
                    playOff()
                    // 設置背景圖片
                    stopButton.setBackgroundImage(UIImage(named: "stop_on"), for: .normal)
                    //formateTimer(timers: Timer)
                }//停止
                else if recbytes[3] == 3 {
                    //hourglassON_Flag = true
                    //playON_Flag = true
                    //hourglassOn()
                }
                FirstLaunch = false
            }
            
            if playON_Flag == true && (recbytes[3] == 1 || recbytes[3] == 2) {
                let Timer = ((Int(recbytes[4]) * 65536) + (Int(recbytes[5]) * 256) + Int(recbytes[6]))
                print(Timer)
                formateTimer(timers: Timer)
            }
            
        } else if characteristic.uuid.uuidString != CharacteristicUUID{
            let uuid = characteristic.uuid.uuidString
            //print(uuid)
            if uuid != "2A23" && uuid != "2A28" && uuid != "2A2A" && uuid != "2A50"{
                var value:String = ""
                value = String(data: data, encoding: .utf8)!
                print(value)
                var title:String = ""
                
                if (uuid == "2A29") {
                    title = NSLocalizedString("div_manufacturer_name", comment: "")
                }else if (uuid == "2A24") {
                    title = NSLocalizedString("div_model_name", comment: "")
                }else if (uuid == "2A25") {
                    title = NSLocalizedString("div_serial_name", comment: "")
                }else if (uuid == "2A27") {
                    title = NSLocalizedString("div_hardware_name", comment: "")
                }else if (uuid == "2A26") {
                    title = NSLocalizedString("div_firmware_name", comment: "")
                }
                
                btServices.append(BTServiceInfo(uuid: title, characteristics: value))
            }
        }
        
        // 操作的characteristic 保存
        self.savedCharacteristic = characteristic
    }
    
    //寫入數據
    func characteristicWriteValue(_ peripheral: CBPeripheral,didWriteValueFor characteristic: CBCharacteristic,value : [UInt8] ) -> () {
        let data:Data = dataWithHexstring(value)

        //只有 characteristic.properties 有write的權限才可以寫
        if characteristic.properties.contains(CBCharacteristicProperties.write){
            //設置为  寫入有反饋
            self.connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
        }else{
            print("寫入不可用~")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil{
            print("寫入 characteristics 時 \(String(describing: peripheral.name)) 報錯 \(String(describing: error?.localizedDescription))")
        }
        
        let alertView = UIAlertController.init(title: "抱歉", message: "寫入成功", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: "好的", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        alertView.show(self, sender: nil)
        lastString = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        
    }
    
    func formateTimer(timers: Int){
        getbytes[4] = UInt8(Int(timers) / 65536)
        getbytes[5] = UInt8((Int(timers) % 65536) / 256)
        getbytes[6] = UInt8((Int(timers) % 65536) % 256)
        timebytes[0] = getbytes[4]
        timebytes[1] = getbytes[5]
        timebytes[2] = getbytes[6]

        var time = timers
        var hour = 0
        if time >= 3600{
            hour = time / 3600
            time = time - (hour * 3600)
        }
        
        var minute = 0;
        if time >= 60 {
            minute = Int(time / 60)
            time = time - (minute * 60)
        }
        
        let sec = Int(time)
        
        hoursLabel.text = String(format: "%02D", hour)
        minuteLabel.text = String(format: "%02D", minute)
        secondLabel.text = String(format: "%02D", sec)
    }
    
    /**
     將[UInt8]陣列轉換为NSData
     
     - parameter bytes: <#bytes description#>
     
     - returns: <#return value description#>
     */
    
    func dataWithHexstring(_ bytes:[UInt8]) -> Data {
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        return data
    }
    
}

