//
//  TransferTaskTableViewController.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/5/11.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialShadowLayer
import Material
private let reuseIdentifier = "cellreuseIdentifier"

class TransferTaskTableViewController: BaseViewController {
    lazy var downloadURLStrings = [String]()
    lazy var downloadNameStrings = [String]()
    var downloadManager: TRManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        appBar.headerViewController.headerView.trackingScrollView = tableView
        self.appBar.navigationBar.title = LocalizedString(forKey: "transfer")
        downloadManager = FilesRootViewController.downloadManager
        
        // 因为会读取缓存到沙盒的任务，所以第一次的时候，不要马上开始下载
        downloadManager?.isStartDownloadImmediately = false
        setupManager()
        self.view.addSubview(self.tableView)
        self.view.bringSubview(toFront: appBar.headerViewController.headerView)
    }
    
    func updateUI() {
        guard let downloadManager = downloadManager else { return  }
//        totalTasksLabel.text = "总任务：\(downloadManager.completedTasks.count)/\(downloadManager.tasks.count)"
//        totalSpeedLabel.text = "总速度：\(downloadManager.speed.tr.convertSpeedToString())"
//        timeRemainingLabel.text = "剩余时间： \(downloadManager.timeRemaining.tr.convertTimeToString())"
//        let per = String(format: "%.2f", downloadManager.progress.fractionCompleted)
//        totalProgressLabel.text = "总进度： \(per)"
    }
    
    func setupManager() {
        
        // 设置manager的回调
        downloadManager?.progress { [weak self] (manager) in
//            guard let strongSelf = self else { return }
            self?.updateUI()
            
            }.success{ [weak self] (manager) in
//                guard let strongSelf = self else { return }
                self?.updateUI()
                if manager.status == .suspend {
                    // manager 暂停了
                }
                if manager.status == .completed {
                    // manager 完成了
                    print("下载完成")
                }
            }.failure { [weak self] (manager) in
//                guard let strongSelf = self,
//                    let downloadManager = strongSelf.downloadManager
//                    else { return }
                self?.downloadURLStrings = (self?.downloadManager?.tasks.map({ $0.URLString }))!
                self?.downloadNameStrings = (self?.downloadManager?.tasks.map({ $0.fileName }))!
                self?.tableView.reloadData()
                self?.updateUI()
                
                if manager.status == .failed {
                    // manager 失败了
                }
                if manager.status == .cancel {
                    // manager 取消了
                    print("下载取消")
                }
                if manager.status == .remove {
                    // manager 移除了
                }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.appBar.headerViewController.headerView.isHidden = false
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        guard let downloadManager = downloadManager else { return  }
        downloadURLStrings = downloadManager.tasks.map({ $0.URLString })
        downloadNameStrings = downloadManager.tasks.map({ $0.fileName })
        updateUI()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if (self.navigationDrawerController?.rootViewController) != nil {
//            let tab = self.navigationDrawerController?.rootViewController as! WSTabBarController
//            tab.setTabBarHidden(false, animated: true)
//        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func rightBarButtonItem(_ sender:UIBarButtonItem){
       let bottomSheet = AppBottomSheetController.init(contentViewController: transferTaskBottomSheetContentVC)
        self.present(bottomSheet, animated: true, completion: nil)
    }
    
    func readFile(filePath:String){
        documentController.url = URL.init(fileURLWithPath: filePath)
        let  canOpen = self.documentController.presentPreview(animated: true)
        if (!canOpen) {
            Message.message(text: LocalizedString(forKey: "File preview failed"))
            documentController.presentOptionsMenu(from: self.view.bounds, in: self.view, animated: true)
        }
    }

    lazy var tableView: UITableView = {
        let tbView = UITableView.init(frame: CGRect(x: 0, y: 0, width: __kWidth, height: __kHeight - MDCAppNavigationBarHeight))
        tbView.delegate = self
        tbView.dataSource = self
        tbView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        tbView.tableFooterView = UIView.init(frame: CGRect.zero)
        tbView.register(UINib.init(nibName: "TransferTaskTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        return tbView
    }()
    
    lazy var rightBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem.init(image:Icon.moreHorizontal?.byTintColor(LightGrayColor) , style: UIBarButtonItemStyle.done, target: self, action: #selector(rightBarButtonItem(_ :)))
        return barButtonItem
    }()
    
    lazy var transferTaskBottomSheetContentVC: TransferTaskBottomSheetContentTableViewController = {
        let vc = TransferTaskBottomSheetContentTableViewController.init(style: UITableViewStyle.plain)
        vc.delegate = self
        return vc
    }()
    
    lazy var documentController: UIDocumentInteractionController = {
       let doucumentController = UIDocumentInteractionController.init()
        doucumentController.delegate = self
        return doucumentController
    }()
    
//    lazy var finishImageView: UIImageView = {
//
//        return imageView
//    }()
}

 // MARK: - Table view data source
extension TransferTaskTableViewController:UITableViewDataSource{
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell:TransferTaskTableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TransferTaskTableViewCell
    cell.selectionStyle = .none
    
    let URLString = downloadURLStrings[indexPath.row]
    guard let downloadManager = downloadManager,
        let task = downloadManager.fetchTask(URLString)
        
        else { return cell }
    cell.titleLabel.text = task.fileName
    cell.leftImageView.image = UIImage.init(named: FileTools.switchFilesFormatType(type: FilesType.file, format: FilesFormatType(rawValue: task.fileName)))
    cell.detailImageView.image = #imageLiteral(resourceName: "files_download_transfer.png")
    var image: UIImage?
    switch task.status {
    case .running:
        break
    case .suspend:
        break
    case .completed:
        image = #imageLiteral(resourceName: "file_finish.png")
    case .waiting:
        break
    default: break
    }
    cell.controlButton.setImage(image, for: .normal)
    cell.updateProgress(task: task)
    
//    let imageViewWidth:CGFloat = 24
//    let imageView = UIImageView.init(frame: CGRect(x:cell.width - 16 - imageViewWidth, y: cell.height/2 - imageViewWidth/2, width: imageViewWidth, height: imageViewWidth))
//    imageView.image = UIImage.init(named: "files_error.png")
//    cell.contentView.addSubview(imageView)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return downloadURLStrings.count
    }
}

extension TransferTaskTableViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction.init(style: UITableViewRowActionStyle.default, title: LocalizedString(forKey: "delete")) { [weak self](tableViewForAction, indexForAction) in
            guard let downloadManager = self?.downloadManager else { return  }
            let count = self?.downloadURLStrings.count
            guard count! > 0 else { return }
            
            let index = indexForAction.row
            let URLString = self?.downloadURLStrings[index]
            self?.downloadURLStrings.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            downloadManager.remove(URLString!, completely: false)
            self?.updateUI()
        }
        deleteRowAction.backgroundColor = UIColor.red
        let priorityRowAction = UITableViewRowAction.init(style: UITableViewRowActionStyle.default, title: LocalizedString(forKey: "priority_transfer")) { (tableViewForAction, indexForAction) in
            
        }
        priorityRowAction.backgroundColor = UIColor.purple
        return [deleteRowAction,priorityRowAction]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let URLString = downloadURLStrings[indexPath.row]
        guard let downloadManager = downloadManager,
            let task = downloadManager.fetchTask(URLString)
            
            else { return  }
        if task.cache.fileExists(fileName: downloadNameStrings[indexPath.row]){
            self.readFile(filePath: task.cache.filePtah(fileName: downloadNameStrings[indexPath.row])!)
        }else{
            Message.message(text: LocalizedString(forKey: "File not exist"))
        }
    }
    
    // 每个cell中的状态更新，应该在willDisplay中执行
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let URLString = downloadURLStrings.safeObjectAtIndex(indexPath.row),
            let task = downloadManager?.fetchTask(URLString)
            else { return }
        
        task.progress { [weak cell] (task) in
            guard let cell = cell as? TransferTaskTableViewCell else { return }
//            cell.updateProgress(task: task)
            }
            .success({ [weak cell] (task) in
                guard let cell = cell as? TransferTaskTableViewCell else { return }
//                cell.controlButton.setImage(#imageLiteral(resourceName: "suspend"), for: .normal)
                if task.status == .suspend {
                    // 下载任务暂停了
                }
                if task.status == .completed {
                    // 下载任务完成了
                    cell.controlButton.setImage(#imageLiteral(resourceName: "file_finish.png"), for: .normal)
                }
            })
            .failure({ [weak cell] (task) in
                guard let cell = cell as? TransferTaskTableViewCell else { return }
//                cell.controlButton.setImage(#imageLiteral(resourceName: "suspend"), for: .normal)
                
                if task.status == .failed {
                    // 下载任务失败了
                }
                if task.status == .cancel {
                    // 下载任务取消了
                }
                if task.status == .remove {
                    // 下载任务移除了
                }
            })
    }
    
    // 由于cell是循环利用的，不在可视范围内的cell，不应该去更新cell的状态
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let URLString = downloadURLStrings.safeObjectAtIndex(indexPath.row),
            let task = downloadManager?.fetchTask(URLString)
            else { return }
        
        task.progress { _ in }.success({ _ in }).failure({ _ in})
    }
}


extension TransferTaskTableViewController:TransferTaskBottomSheetContentVCDelegate{
    func transferTaskBottomSheettableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.transferTaskBottomSheetContentVC.presentingViewController?.dismiss(animated: true, completion: {
            
        })
    }
}

extension TransferTaskTableViewController:UIDocumentInteractionControllerDelegate{
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return self.view.frame
    }
}
