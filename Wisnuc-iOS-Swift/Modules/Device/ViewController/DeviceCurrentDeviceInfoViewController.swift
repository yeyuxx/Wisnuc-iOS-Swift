//
//  DeviceCurrentDeviceInfoViewController.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/10/17.
//  Copyright © 2018 wisnuc-imac. All rights reserved.
//

import UIKit

class DeviceCurrentDeviceInfoViewController: BaseViewController {
    let identifier = "celled"
    var model:WinasdInfoModel?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.largeTitle = LocalizedString(forKey: "关于本机")
        self.view.addSubview(infoSettingTableView)
        self.view.bringSubview(toFront: appBar.appBarViewController.headerView)
        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appBar.headerViewController.headerView.trackingScrollView = self.infoSettingTableView
        appBar.appBarViewController.headerView.observesTrackingScrollViewScrollEvents = true
        ViewTools.automaticallyAdjustsScrollView(scrollView: self.infoSettingTableView, viewController: self)
    }
    
    deinit {
            // Required for pre-iOS 11 devices because we've enabled observesTrackingScrollViewScrollEvents.
        appBar.appBarViewController.headerView.trackingScrollView = nil
    }
    
    func loadData(){
        DeviceHelper.fetchInasdInfo(closure:  { [weak self](model) in
            self?.model = model
            self?.infoSettingTableView.reloadData()
        })
    }
    
    lazy var infoSettingTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: __kWidth, height: __kHeight), style: UITableViewStyle.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        return tableView
    }()
}

extension DeviceCurrentDeviceInfoViewController:UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: identifier)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = LocalizedString(forKey: "蓝牙地址")
            cell.detailTextLabel?.text = self.model?.ble?.address
        case 1:
            cell.textLabel?.text = LocalizedString(forKey:"设备身份")
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = LocalizedString(forKey:"加密芯片")
            cell.detailTextLabel?.text = self.model?.device?.ecc
        case 3:
            cell.textLabel?.text = LocalizedString(forKey:"网卡宽带")
            if let speed = self.model?.net?.networkInterface?.speed{
              cell.detailTextLabel?.text =  "\(speed)Mbps"
            }
        default:
            break
        }
        
        cell.textLabel?.textColor = DarkGrayColor
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.textColor = LightGrayColor
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0{
            switch indexPath.row {
            case 1:
                if let model = self.model{
                let deviceIdentityViewController = DeviceIdentityViewController.init(style:.highHeight,model:model  )
                self.navigationController?.pushViewController(deviceIdentityViewController, animated: true)
                }
            default:
                break
            }
        }else{
            
        }
    }
}
