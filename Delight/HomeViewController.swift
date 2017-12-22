<<<<<<< HEAD
//
//  ViewController.swift
//  Delight
//
//  Created by mac on 2017/7/14.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

class HomeViewController: BaseViewController{
    
    @IBOutlet weak var customTableView: UITableView!

    //系统蓝牙管理对象
    var myCentralManager:CBCentralManager!
    var selectedPeripheral: CBPeripheral?
 
    //陣列集合
    var discoveredPeripheralsArr :[ScanDeviceDATA] = [ScanDeviceDATA]()
    //设备名
    var DEVICENAME:String = "Delight"
    
    var tableView:UITableView?
    //下拉刷新控制器
    var refreshControl: UIRefreshControl!
    
    var timer: Timer!
    
    let deviceSaveInfo = deviceSave()
    var SelectDeviceMACAddress:String = ""
    var SelectDeviceName:String = ""

    var DeviceNumber:Int = 1
    
    var headerView:UIView!
    var headerlabel:UILabel!

    deinit {
        // perform the deinitialization
        print("Home is dead")
    }
    
    override func loadView() {
        //視圖初始化執行
        super.loadView()
        print("loadView")
        print("藍牙初始")
        //藍牙初始
        myCentralManager = CBCentralManager(delegate: self, queue: nil)
        print(myCentralManager)
    }
    
    override func viewDidLoad() {
        //視圖初始化執行
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addSlideMenuButton()
        print("HomeViewController")
        
        self.title = "Delight"
        
        self.customTableView.delegate = self
        self.customTableView.dataSource = self
        
        //添加刷新
        refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(refreshData),
                                       for: .valueChanged)
        self.customTableView!.addSubview(refreshControl)

        //設置表格背景色
        self.customTableView!.backgroundColor = UIColor(red: 0xf0/255, green: 0xf0/255,
                                                  blue: 0xf0/255, alpha: 1)
        //去除單元格分隔线
        self.customTableView!.separatorStyle = .none
        
        // remove the blank of the header of the table view, mind the height must be more than 0        
        self.customTableView.tableHeaderView = UIView(frame: CGRect(x:0, y:0, width:self.customTableView.frame.size.width, height:0.01))
        self.customTableView.tableHeaderView?.frame.size.height = 0.01
        
        // register the custom tableview cell
        let nib = UINib(nibName: "MyTableViewCell", bundle: nil)
        self.customTableView.register(nib, forCellReuseIdentifier: "myCell")
        
        //给TableView添加表头页眉
        headerView = UIView(frame:
            CGRect(x:0, y:0, width:customTableView!.frame.size.width, height:60))
        headerlabel = UILabel(frame: headerView.bounds)
        headerlabel.textColor = UIColor.white
        headerlabel.backgroundColor = UIColor.clear
        headerlabel.font = UIFont.systemFont(ofSize: 16)
        headerlabel.textAlignment = NSTextAlignment.center
        headerlabel.text = NSLocalizedString("profile_control_no_device_message", comment: "") //請下拉搜尋設備...
        headerView.addSubview(headerlabel)
        headerView.backgroundColor = UIColor.black
        customTableView?.tableHeaderView = headerView
     }
    
    override func viewWillAppear(_ animated: Bool) {
        //視圖顯示完成前執行
        print("Home viewWillAppear")
        Disconnect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //視圖顯示完成執行
        print("Home viewDidAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //視圖消失前執行
        print("Home viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //視圖消失執行
        super.viewDidDisappear(animated)
        
        print("Home ViewDidDisappear")
    }
    
    override func didReceiveMemoryWarning() {
        //收到內存警告時提醒
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Disconnect(){
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;   //啟用側滑手勢
        myCentralManager.delegate = self
        if selectedPeripheral != nil  {
            let connectState:Int = (selectedPeripheral?.state.hashValue)!
            print(connectState)
            if connectState == 2 {
                let alertController = UIAlertController.init(title: "\(SelectDeviceName)  \n \(NSLocalizedString("alert_message_bluetooth_disconnect", comment: ""))", message: nil, preferredStyle: .alert)
                self.present(alertController, animated: true)  //開啟提醒視窗
                
                myCentralManager.cancelPeripheralConnection(selectedPeripheral!)
                print(selectedPeripheral!);
                
                //兩秒鐘後自動消失
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                    
                }
            }
            refreshData()
        }
    }
    
    // 更新資料
    func refreshData() { 
        headerlabel.text = NSLocalizedString("profile_control_device_scanning", comment: "") //尋找設備中，請稍候......
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self,
                                     selector: #selector(HomeViewController.timeOut), userInfo: nil, repeats: true)
        
        headerView.backgroundColor = UIColor.black
        print("掃瞄設備。。。。 ");
        self.discoveredPeripheralsArr.removeAll()
        startScan()
        
   }
    
    //計時器時間到
    func timeOut() {
        headerView.backgroundColor = UIColor.blue
        headerlabel.text = NSLocalizedString("profile_control_no_device_message", comment: "") //請下拉搜尋設備...
        stopScan()
        
        self.refreshControl!.endRefreshing()
        
        print("timeOut")
 
        timer.invalidate()
        timer = nil
        DeviceNumber = 1
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
            selectedPeripheral = sender as? CBPeripheral
            controller.peripheral = selectedPeripheral
            controller.myCentralManager = self.myCentralManager
            controller.ConnectMACAddress = SelectDeviceMACAddress
            controller.DeviceName = SelectDeviceName
        }
    }
}

//--藍牙------------------------------------------
extension HomeViewController :CBCentralManagerDelegate,CBPeripheralDelegate{
    func startScan() {
        myCentralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        //關閉掃描
        myCentralManager.stopScan()
    }
    
    func isBluetoothAvailable() -> Bool {
        if #available(iOS 10.0, *) {
            return myCentralManager.state == CBManagerState.poweredOn
        } else {
            return myCentralManager.state == .poweredOn
        }
    }
    
    @available(iOS 5.0, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //藍牙狀態
        print("-----centralManagerDidUpdateState----------")
        print(central.state)
        switch central.state {
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        case .poweredOff:
            print("CBCentralManagerStatePoweredOff")
        case .poweredOn:
            print("CBCentralManagerStatePoweredOn")
            refreshData()
            
        }
    }
    
    //發現設備
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("--didDiscoverPeripheral-")
        
        if (peripheral.name?.contains(DEVICENAME))!{
            print(peripheral)
            
            var isExisted = false
            for obtainedPeriphal  in discoveredPeripheralsArr {
                if (obtainedPeriphal.devicePeripheral.identifier == peripheral.identifier){
                    isExisted = true
                }
            }
            
            if !isExisted{
                let mac:Data = advertisementData[CBAdvertisementDataManufacturerDataKey] as! Data
                
                let SourceMacAddress  = Array(UnsafeBufferPointer(start: (mac as NSData).bytes.bindMemory(to: UInt8.self, capacity: mac.count-2), count: mac.count-2))
                
                var MACAddress:[String] = [String]()
            
                 for i in 0 ..< SourceMacAddress.count {
                    MACAddress.append(HexUtil.encodeToString([SourceMacAddress[i]]))
                }
                
                let TargetMacAddress = MACAddress[0] + ":" + MACAddress[1] + ":"  + MACAddress[2] + ":"  + MACAddress[3] + ":"  + MACAddress[4] + ":"  + MACAddress[5]
                
                let Device = deviceSaveInfo.read(address: TargetMacAddress)
                var DeviceName:String = ""
                
                if Device != nil{
                    let dL1 = try! JSONSerialization.jsonObject(with:Device! as Data, options: .mutableContainers) as! NSDictionary
                    DeviceName = dL1.value(forKey: "deviceName")! as! String
                }else{
                    DeviceName = (advertisementData[CBAdvertisementDataLocalNameKey]as! CFString) as String  + "_" + String(DeviceNumber)
                }
                
                let device = ScanDeviceDATA(
                    Name: DeviceName,
                    devicePeripheral: peripheral,
                    Address: TargetMacAddress
                )
                
                print(device.Address)
                DeviceNumber += 1
                self.discoveredPeripheralsArr.append(device)
            }
            
        self.customTableView?.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, andAdvertisementData1: [String : Any], rssi RSSI: NSNumber) {
    }

}


//--Table-----------------------------------------------------------------------
extension HomeViewController :UITableViewDelegate, UITableViewDataSource{
    //滾動視圖開始拖動
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !refreshControl.isRefreshing {
            //refreshControl!.attributedTitle = NSAttributedString(string: "下拉更新資料...")
        }
    }
    
    //在本例中，只有一個分區
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    //返回表格行數（也就是返回控件數）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.discoveredPeripheralsArr.count
    }
    
    //單元格高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat {
            return 100
    }
    
    //創建各單元顯示内容(創建参樹indexPath指定的單元）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell:MyTableViewCell = tableView.dequeueReusableCell(withIdentifier: "myCell")
            as! MyTableViewCell
        
        //設置單元格標題(藍牙名稱)
        let device: ScanDeviceDATA = discoveredPeripheralsArr[indexPath.row] as ScanDeviceDATA
        cell.customImage.image = UIImage(named: "delight")
        cell.customLabel?.text = device.Name //+ "_" + String(describing: indexPath.row + 1)
        if (device.Name?.contains("110"))!{ //切換Product Size 圖片
            cell.customImage.image = UIImage(named: "d_110")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        myCentralManager.stopScan()
        let device: ScanDeviceDATA = discoveredPeripheralsArr[indexPath.row] as ScanDeviceDATA
        SelectDeviceMACAddress = device.Address
        SelectDeviceName = device.Name

        //跳轉到藍牙控制介面
        self.performSegue(withIdentifier: "goBluetooth", sender: device.devicePeripheral)
    }
   
}

||||||| merged common ancestors
=======
//
//  ViewController.swift
//  Delight
//
//  Created by mac on 2017/7/14.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

class HomeViewController: BaseViewController{
    
    @IBOutlet weak var customTableView: UITableView!

    //系统蓝牙管理对象
    var myCentralManager:CBCentralManager!
    var selectedPeripheral: CBPeripheral?
 
    //陣列集合
    var discoveredPeripheralsArr :[ScanDeviceDATA] = [ScanDeviceDATA]()
    //设备名
    var DEVICENAME:String = "Delight BLE"
    
    var tableView:UITableView?
    //下拉刷新控制器
    var refreshControl: UIRefreshControl!
    
    var timer: Timer!
    
    let deviceSaveInfo = deviceSave()
    var SelectDeviceMACAddress:String = ""
    var SelectDeviceName:String = ""

    var DeviceNumber:Int = 1
    
    var headerView:UIView!
    var headerlabel:UILabel!

    deinit {
        // perform the deinitialization
        print("Home is dead")
    }
    
    override func loadView() {
        //視圖初始化執行
        super.loadView()
        print("loadView")
        print("藍牙初始")
        //藍牙初始
        myCentralManager = CBCentralManager(delegate: self, queue: nil)
        print(myCentralManager)
    }
    
    override func viewDidLoad() {
        //視圖初始化執行
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addSlideMenuButton()
        print("HomeViewController")
        
        self.title = "Delight"
        
        self.customTableView.delegate = self
        self.customTableView.dataSource = self
        
        //添加刷新
        refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(refreshData),
                                       for: .valueChanged)
        self.customTableView!.addSubview(refreshControl)

        //設置表格背景色
        self.customTableView!.backgroundColor = UIColor(red: 0xf0/255, green: 0xf0/255,
                                                  blue: 0xf0/255, alpha: 1)
        //去除單元格分隔线
        self.customTableView!.separatorStyle = .none
        
        // remove the blank of the header of the table view, mind the height must be more than 0        
        self.customTableView.tableHeaderView = UIView(frame: CGRect(x:0, y:0, width:self.customTableView.frame.size.width, height:0.01))
        self.customTableView.tableHeaderView?.frame.size.height = 0.01
        
        // register the custom tableview cell
        let nib = UINib(nibName: "MyTableViewCell", bundle: nil)
        self.customTableView.register(nib, forCellReuseIdentifier: "myCell")
        
        //给TableView添加表头页眉
        headerView = UIView(frame:
            CGRect(x:0, y:0, width:customTableView!.frame.size.width, height:60))
        headerlabel = UILabel(frame: headerView.bounds)
        headerlabel.textColor = UIColor.white
        headerlabel.backgroundColor = UIColor.clear
        headerlabel.font = UIFont.systemFont(ofSize: 16)
        headerlabel.textAlignment = NSTextAlignment.center
        headerlabel.text = NSLocalizedString("profile_control_no_device_message", comment: "") //請下拉搜尋設備...
        headerView.addSubview(headerlabel)
        headerView.backgroundColor = UIColor.black
        customTableView?.tableHeaderView = headerView
     }
    
    override func viewWillAppear(_ animated: Bool) {
        //視圖顯示完成前執行
        print("Home viewWillAppear")
        Disconnect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //視圖顯示完成執行
        print("Home viewDidAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //視圖消失前執行
        print("Home viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //視圖消失執行
        super.viewDidDisappear(animated)
        
        print("Home ViewDidDisappear")
    }
    
    override func didReceiveMemoryWarning() {
        //收到內存警告時提醒
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Disconnect(){
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;   //啟用側滑手勢
        myCentralManager.delegate = self
        if selectedPeripheral != nil  {
            let connectState:Int = (selectedPeripheral?.state.hashValue)!
            print(connectState)
            if connectState == 2 {
                let alertController = UIAlertController.init(title: "\(SelectDeviceName)  \n \(NSLocalizedString("alert_message_bluetooth_disconnect", comment: ""))", message: nil, preferredStyle: .alert)
                self.present(alertController, animated: true)  //開啟提醒視窗
                
                myCentralManager.cancelPeripheralConnection(selectedPeripheral!)
                print(selectedPeripheral!);
                
                //兩秒鐘後自動消失
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                    
                }
            }
            refreshData()
        }
    }
    
    // 更新資料
    func refreshData() { 
        headerlabel.text = NSLocalizedString("profile_control_device_scanning", comment: "") //尋找設備中，請稍候......
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self,
                                     selector: #selector(HomeViewController.timeOut), userInfo: nil, repeats: true)
        
        headerView.backgroundColor = UIColor.black
        print("掃瞄設備。。。。 ");
        self.discoveredPeripheralsArr.removeAll()
        startScan()
        
   }
    
    //計時器時間到
    func timeOut() {
        headerView.backgroundColor = UIColor.blue
        headerlabel.text = NSLocalizedString("profile_control_no_device_message", comment: "") //請下拉搜尋設備...
        stopScan()
        
        self.refreshControl!.endRefreshing()
        
        print("timeOut")
 
        timer.invalidate()
        timer = nil
        DeviceNumber = 1
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
            selectedPeripheral = sender as? CBPeripheral
            controller.peripheral = selectedPeripheral
            controller.myCentralManager = self.myCentralManager
            controller.ConnectMACAddress = SelectDeviceMACAddress
            controller.DeviceName = SelectDeviceName
        }
    }
}

//--藍牙------------------------------------------
extension HomeViewController :CBCentralManagerDelegate,CBPeripheralDelegate{
    func startScan() {
        myCentralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        //關閉掃描
        myCentralManager.stopScan()
    }
    
    func isBluetoothAvailable() -> Bool {
        if #available(iOS 10.0, *) {
            return myCentralManager.state == CBManagerState.poweredOn
        } else {
            return myCentralManager.state == .poweredOn
        }
    }
    
    @available(iOS 5.0, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //藍牙狀態
        print("-----centralManagerDidUpdateState----------")
        print(central.state)
        switch central.state {
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        case .poweredOff:
            print("CBCentralManagerStatePoweredOff")
        case .poweredOn:
            print("CBCentralManagerStatePoweredOn")
            refreshData()
            
        }
    }
    
    //發現設備
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("--didDiscoverPeripheral-")
        
        if peripheral.name == DEVICENAME{
            var isExisted = false
            for obtainedPeriphal  in discoveredPeripheralsArr {
                if (obtainedPeriphal.devicePeripheral.identifier == peripheral.identifier){
                    isExisted = true
                }
            }
            
            if !isExisted{
                let mac:Data = advertisementData[CBAdvertisementDataManufacturerDataKey] as! Data
                
                let SourceMacAddress  = Array(UnsafeBufferPointer(start: (mac as NSData).bytes.bindMemory(to: UInt8.self, capacity: mac.count-2), count: mac.count-2))
                
                var MACAddress:[String] = [String]()
            
                 for i in 0 ..< SourceMacAddress.count {
                    MACAddress.append(HexUtil.encodeToString([SourceMacAddress[i]]))
                }
                
                let TargetMacAddress = MACAddress[0] + ":" + MACAddress[1] + ":"  + MACAddress[2] + ":"  + MACAddress[3] + ":"  + MACAddress[4] + ":"  + MACAddress[5]
                
                let Device = deviceSaveInfo.read(address: TargetMacAddress)
                var DeviceName:String = ""
                
                if Device != nil{
                    let dL1 = try! JSONSerialization.jsonObject(with:Device! as Data, options: .mutableContainers) as! NSDictionary
                    DeviceName = dL1.value(forKey: "deviceName")! as! String
                }else{
                    DeviceName = peripheral.name! + "_" + String(DeviceNumber)
                }
                
                let device = ScanDeviceDATA(
                    Name: DeviceName,
                    devicePeripheral: peripheral,
                    Address: TargetMacAddress
                )
                
                print(device.Address)
                DeviceNumber += 1
                self.discoveredPeripheralsArr.append(device)
            }
            
        self.customTableView?.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, andAdvertisementData1: [String : Any], rssi RSSI: NSNumber) {
    }

}


//--Table-----------------------------------------------------------------------
extension HomeViewController :UITableViewDelegate, UITableViewDataSource{
    //滾動視圖開始拖動
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !refreshControl.isRefreshing {
            //refreshControl!.attributedTitle = NSAttributedString(string: "下拉更新資料...")
        }
    }
    
    //在本例中，只有一個分區
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    //返回表格行數（也就是返回控件數）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.discoveredPeripheralsArr.count
    }
    
    //單元格高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat {
            return 100
    }
    
    //創建各單元顯示内容(創建参樹indexPath指定的單元）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell:MyTableViewCell = tableView.dequeueReusableCell(withIdentifier: "myCell")
            as! MyTableViewCell
        
        //設置單元格標題(藍牙名稱)
        let device: ScanDeviceDATA = discoveredPeripheralsArr[indexPath.row] as ScanDeviceDATA
        cell.customLabel?.text = device.Name //+ "_" + String(describing: indexPath.row + 1)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        myCentralManager.stopScan()
        let device: ScanDeviceDATA = discoveredPeripheralsArr[indexPath.row] as ScanDeviceDATA
        SelectDeviceMACAddress = device.Address
        SelectDeviceName = device.Name

        //跳轉到藍牙控制介面
        self.performSegue(withIdentifier: "goBluetooth", sender: device.devicePeripheral)
    }
   
}

>>>>>>> aa50565296ecf6faead0a38a54f38e4d9418e9e9
