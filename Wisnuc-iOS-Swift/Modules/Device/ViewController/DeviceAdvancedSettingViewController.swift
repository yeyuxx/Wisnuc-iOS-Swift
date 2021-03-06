//
//  DeviceAdvancedSettingViewController.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/10/17.
//  Copyright © 2018 wisnuc-imac. All rights reserved.
//

import UIKit

class DeviceAdvancedSettingViewController: BaseViewController {
    let identifier = "celled"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.largeTitle = LocalizedString(forKey: "高级")
        self.view.addSubview(advancedSettingTableView)
        self.view.bringSubview(toFront: appBar.appBarViewController.headerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appBar.headerViewController.headerView.trackingScrollView = self.advancedSettingTableView
        appBar.appBarViewController.headerView.observesTrackingScrollViewScrollEvents = true
        ViewTools.automaticallyAdjustsScrollView(scrollView: self.advancedSettingTableView, viewController: self)
        let tab = retrieveTabbarController()
        tab?.setTabBarHidden(true, animated: true)
    }
    
    deinit {
        // Required for pre-iOS 11 devices because we've enabled observesTrackingScrollViewScrollEvents.
        appBar.appBarViewController.headerView.trackingScrollView = nil
    }

    lazy var advancedSettingTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: __kWidth, height: __kHeight), style: UITableViewStyle.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        return tableView
    }()
}

extension DeviceAdvancedSettingViewController:UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let  cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LocalizedString(forKey: "设备用户")
                cell.accessoryType = .disclosureIndicator
//            case 1:
//                cell.textLabel?.text = LocalizedString(forKey:"SAMBA设置")
//                cell.accessoryType = .disclosureIndicator
//            case 1:
//                cell.textLabel?.text = LocalizedString(forKey:"还原")
//                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = LocalizedString(forKey:"关于本机")
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
            
            cell.textLabel?.textColor = DarkGrayColor
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0{
            switch indexPath.row {
            case 0:
                let deviceUsersManageViewController = DeviceUsersManageViewController.init(style:.highHeight)
                self.navigationController?.pushViewController(deviceUsersManageViewController, animated: true)
//            case 1:
//                let sambaSettingViewController = DeviceSambaSettingViewController.init(style:.highHeight)
//                self.navigationController?.pushViewController(sambaSettingViewController, animated: true)
//            case 1:
//                let reductionSettingViewController = DeviceReductionSettingViewController.init(style:.highHeight)
//                self.navigationController?.pushViewController(reductionSettingViewController, animated: true)
            case 1:
                let currentDeviceInfoViewController = DeviceCurrentDeviceInfoViewController.init(style:.highHeight)
                self.navigationController?.pushViewController(currentDeviceInfoViewController, animated: true)
            default:
                break
            }
        }else{
            
        }
    }
}



