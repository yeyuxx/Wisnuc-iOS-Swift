//
//  SeekNewDeviceViewController.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/9/13.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import CoreBluetooth
enum SeekNewDeviceState {
    case found
    case notFound
    case bleNotOpen
    case searching
}
class SeekNewDeviceViewController: BaseViewController {
    private let headerViewHeight:CGFloat = 64
    let cellReuseIdentifier = "cell"
    var user:User?
    lazy var dataSource:Array<DeviceBLEModel> = [DeviceBLEModel]()
    lazy var dataPeripheralList:Array<CBPeripheral> = [CBPeripheral]()
    var state:SeekNewDeviceState?{
        didSet{
            switch state {
            case .searching?:
                searchingStateAction()
            case .notFound?:
                notFoundStateAction()
            case .found?:
                foundStateAction()
            case .bleNotOpen?:
                bleNotOpenAction()
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.deviceTableView.register(UINib.init(nibName: StringExtension.classNameAsString(targetClass: SeekNewDeviceTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
        self.view.addSubview(titleLabel)
        self.view.addSubview(deviceTableView)
        self.view.bringSubview(toFront: appBar.headerViewController.headerView)
        self.state = .searching
//        self.setData()
         defaultNotificationCenter().addObserver(self, selector: #selector(confirmFinish(_:)), name: NSNotification.Name.Config.DiskFormaConfirmDismissKey, object: nil)
        deviceTableView.addSubview(errorLabel)
      
//        self.title = "发现设备"
//        appBar.navigationBar.ti
    }
    
    init(style: NavigationStyle,user:User? = nil) {
        super.init(style: style)
        self.user = user
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LLBlueTooth.instance.disConnectPeripherals(dataPeripheralList)
        LLBlueTooth.instance.dispose()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appBar.headerViewController.headerView.trackingScrollView = self.deviceTableView
        LLBlueTooth.instance.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LLBlueTooth.instance.stopScan()
    }
    
    func searchingStateAction(){
        titleLabel.text = LocalizedString(forKey: "搜索设备中...")
        let options =  [CBCentralManagerScanOptionAllowDuplicatesKey:false]
        LLBlueTooth.instance.scanForPeripheralsWithServices(nil, options: options as [String : AnyObject])
    }
    
    func notFoundStateAction(){
        titleLabel.text = LocalizedString(forKey: "未发现设备")
        dataSource.removeAll()
        titleLabel.text = LocalizedString(forKey: "附近无可用设备")
        errorLabel.isHidden = false
        deviceTableView.reloadData()
    }
    
    func foundStateAction(){
        titleLabel.text = LocalizedString(forKey: "发现设备")
         errorLabel.isHidden = true
    }
    
    func  bleNotOpenAction(){
        dataSource.removeAll()
        titleLabel.text = LocalizedString(forKey: "未发现设备")
        deviceTableView.reloadData()
        errorLabel.isHidden = false
        errorLabel.eventCallback = { () in
            //进入系统设置打开蓝牙
            if kCurrentSystemVersion <= 10.0 {
                UIApplication.shared.openURL(URL.init(string: "prefs:root=Bluetooth")!)
            }else {
                let url = URL.init(string: "App-Prefs:root=General&path=Bluetooth")
                UIApplication.shared.openURL(url!)
            }
        }
    }
    
    @objc func confirmFinish(_ noti:Notification){
        let configNetVC = ConfigNetworkViewController.init(style: .whiteWithoutShadow,state:.initialization,user:self.user)
        self.navigationController?.pushViewController(configNetVC, animated: true)
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel.init(frame: CGRect(x: MarginsWidth, y: 64/2 - 22/2, width: __kWidth - MarginsWidth*2, height: 22))
        label.font = UIFont.boldSystemFont(ofSize: 21)
        label.textColor = DarkGrayColor
        return label
    }()
    
    lazy var deviceTableView: UITableView = { [weak self] in
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: __kWidth, height: __kHeight), style: UITableViewStyle.grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .white
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        return tableView
    }()
    
    lazy var errorLabel:AttributeTouchLabel = {
        let string = "需要通过蓝牙发现设备\n蓝牙未打开，前往设置"
        let margin:CGFloat = 100
        let size = labelSizeToFit(title: LocalizedString(forKey: string), font: UIFont.systemFont(ofSize: 16))
        let label = AttributeTouchLabel.init(frame: CGRect(x: margin, y: __kHeight/2 - 50, width: __kWidth - margin*2, height: size.height + 4))
        label.content = string
        label.isHidden = true
        return label
    }()
}

extension SeekNewDeviceViewController:UITableViewDataSource,UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorStyle = .none
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SeekNewDeviceTableViewCell
        let model = dataSource[indexPath.row]
        cell.titleLabel.text = model.stationId
        cell.accessoryType = .none
        switch model.type {
        case .NeedConfig?:
            cell.detailLabel.text = LocalizedString(forKey: "待配置")
            cell.rightImageView.image =  UIImage.init(named: "disclosureIndicator.png")
        case .Done?:
            cell.detailLabel.text = LocalizedString(forKey: "已配置")
            cell.rightImageView.image =  UIImage.init(named: "config_finish.png")
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.row]
        switch model.type {
        case .NeedConfig?:
            guard let user = self.user else {
                return
            }
            let configNetVC = ConfigNetworkViewController.init(style: .whiteWithoutShadow,state:.initialization,user:user)
            configNetVC.deviceModel = model
            self.navigationController?.pushViewController(configNetVC, animated: true)
            LLBlueTooth.instance.stopScan()
        case .Done?:
            Message.message(text: LocalizedString(forKey: "已被绑定，无法使用"))
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init()
        headerView.addSubview(self.titleLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerViewHeight
    }
}


extension SeekNewDeviceViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.deviceTableView{
            let tableView = scrollView as! UITableView
            
            print("\(tableView.contentOffset)")
        }
    }
}

extension SeekNewDeviceViewController:LLBlueToothDelegate{
    func peripheralCharacteristicDidUpdateValue(deviceBLEModels: [DeviceBLEModel]?) {
        if let devices = deviceBLEModels{
            dataSource = devices
            self.state = .found
            self.deviceTableView.reloadData()
        }
       
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            return
        }

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral) {
        //  在这个地方可以判读是不是自己本公司的设备,这个是根据设备的名称过滤的
        guard peripheral.name != nil , peripheral.name!.contains("Wisnuc") else {
            return
        }
        
        if !(dataPeripheralList.contains(peripheral)) {
            dataPeripheralList.append(peripheral)
            LLBlueTooth.instance.requestConnectPeripheral(peripheral)
        }
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch central.state {
                
            case CBManagerState.poweredOn:
                print("蓝牙打开")
                self.state = .searching

            case CBManagerState.unauthorized:
                print("没有蓝牙功能")
                
            case CBManagerState.poweredOff:
                print("蓝牙关闭")
                self.state = .bleNotOpen
                
            default:
                print("未知状态")
            }
        }
    }
}
