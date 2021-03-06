
//
//  AutoBackupManager.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/8/16.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import Alamofire

class AutoBackupManager: NSObject {
    private var isDestroying = false
    private var shouldNotify = false
    private var needRetry = true
    var uuid:String?

    lazy var hashwaitingQueue = Array<WSAsset>.init()
    
    lazy var hashWorkingQueue = Array<WSAsset>.init()
    
    lazy var hashFailQueue = Array<WSAsset>.init()
    
    lazy var uploadPaddingQueue = Array<WSAsset>.init()
    
    lazy var uploadingQueue = Array<WSUploadModel>.init()
    
    lazy var uploadedQueue = Array<WSUploadModel>.init()
    
    lazy var uploadErrorQueue = Array<WSUploadModel>.init()
    
    var sessionManager: SessionManager!
    
    var hashLimitCount:Int? // default 2
    
    var uploadLimitCount:Int? // default 1
    
    var shouldUpload:Bool? {
        didSet{
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = self.shouldUpload!
            }
        }
    }// default NO
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.wisnuc.app.backgroundtransfer")
        sessionManager = Alamofire.SessionManager(configuration: configuration)
        shouldUpload = false
        hashLimitCount = 4
        uploadLimitCount = 4
    }

    func startAutoBcakup() {
        self.shouldUpload = false
        // notify for start
        defaultNotificationCenter().post(name: NSNotification.Name.Backup.AutoBackupCountChangeNotiKey, object: nil)
        self.managerQueue.async { [weak self]  in
            for model in (self?.uploadErrorQueue)!{
                self?.uploadPaddingQueue.append(model.asset!)
            }
            self?.uploadErrorQueue.removeAll()
            self?.shouldUpload = true
            self?.needRetry  = true
            self?.schedule()
        }
    }
    
    func destroy(){
        isDestroying = true
        self.stop()
        removeAll()
//        self.hashwaitingQueue.removeAll()
//        // TODO: cancel working queue?
//        self.hashWorkingQueue.removeAll()
//        self.hashFailQueue.removeAll()
//
//        self.uploadPaddingQueue.removeAll()
//
//        self.uploadingQueue.removeAll()
//        self.uploadedQueue.removeAll()
//        self.uploadErrorQueue.removeAll()
//        self.uploadedNetQueue.removeAll()
//        self.uploadedLocalHashSet.removeAll()
//
        self.sessionManager.session.invalidateAndCancel()
        shouldNotify = false
        needRetry = true
        shouldUpload = false
        isDestroying = false
    }
    
    
    func removeAll(){
        self.hashwaitingQueue.removeAll()
        // TODO: cancel working queue?
        self.hashWorkingQueue.removeAll()
        self.hashFailQueue.removeAll()
        
        self.uploadPaddingQueue.removeAll()
        self.uploadingQueue.removeAll()
        self.uploadedQueue.removeAll()
        self.uploadErrorQueue.removeAll()
        self.uploadedNetQueue.removeAll()
        self.uploadedLocalHashSet.removeAll()
    }
    
    func fetchAllCount(callback:@escaping (_ allCount:Int)->()) {
        self.managerQueue.async {
            let allCount =  self.hashwaitingQueue.count + self.hashWorkingQueue.count + self.hashFailQueue.count
            + self.uploadPaddingQueue.count + self.uploadingQueue.count
            + self.uploadedQueue.count + self.uploadErrorQueue.count
            callback(allCount)
        }
    }

    
    func setNetAssets(netAssets:Array<EntriesModel>){
        managerQueue.async {
            self.uploadedNetQueue = netAssets
            var  hashSet = Set<String>.init()
            for model in netAssets{
                if model.type == FilesType.file.rawValue && model.hash != nil{
                  hashSet.insert(model.hash!)
                }
            }
          
            self.uploadedNetHashSet = hashSet
            self.schedule()
        }
    }
    
    func start(localAssets:Array<WSAsset>,netAssets:Array<EntriesModel>){
        self.managerQueue.async { [weak self] in
            self?.shouldNotify = true
            self?.needRetry = true
            self?.hashwaitingQueue.append(contentsOf: localAssets)
            self?.hashwaitingQueue.sort { $0.createDate! > $1.createDate! }
            self?.uploadedNetQueue.append(contentsOf: netAssets)
            var hashSet = Set<String>.init()
            for model in netAssets{
                if model.type == FilesType.file.rawValue && model.hash != nil{
                    hashSet.insert(model.hash!)
                }
            }
            self?.shouldUpload = false
            self?.uploadedNetHashSet = hashSet
            self?.schedule()
        }
    }
    
    func schedule(){
        if isDestroying {return}
        if(self.hashwaitingQueue.count == 0 && self.hashWorkingQueue.count == 0) {
            if shouldNotify {
                shouldNotify = false
                defaultNotificationCenter().post(name: Notification.Name.Backup.HashCalculateFinishedNotiKey, object: nil)
            }
            print("hash calculate finish. uploadPaddingQueue:\(String(describing: self.uploadPaddingQueue.count))");
        }


        if(self.hashwaitingQueue.count == 0 && self.hashWorkingQueue.count == 0 && self.uploadPaddingQueue.count == 0 && self.uploadingQueue.count == 0){
            print("backup asset finish ----=======>>>><<<<<<<<====-----  errorCount:\(uploadErrorQueue.count)  finishedCount:\(uploadedQueue.count)")

            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            self.managerQueue.async { [weak self] in
                if (self?.uploadErrorQueue.count)!>0 { // retry
                    self?.needRetry = false
                    for model in (self?.uploadErrorQueue)!{
                        if model.asset != nil{
                            self?.uploadPaddingQueue.append(model.asset!)
                        }
                    }
                    self?.uploadErrorQueue.removeAll()
                    self?.schedule()
                }
            }
        }

        self.managerQueue.async { [weak self] in
            while((self?.hashWorkingQueue.count)! < (self?.hashLimitCount!)! && (self?.hashwaitingQueue.count)! > 0) {
                guard let asset = self?.hashwaitingQueue.first else{
                    return
                }
                let location = self?.hashwaitingQueue.index(of: asset)
                if let eLocation = location{
                    self?.hashwaitingQueue.remove(at: eLocation)
                }
                self?.hashWorkingQueue.append(asset)
                self?.workingQueue.async {
                    self?.getAssetSha256(asset: asset, callback: { [weak self] (error, sha256) in
                        self?.managerQueue.async {
                            if (error != nil) {
                                self?.hashFailQueue.append(asset)
                            }else{
                                asset.digest = sha256
                                self?.uploadPaddingQueue.append(asset)
                            }

                            let location = self?.hashWorkingQueue.index(of: asset)
                            if let eLocation = location{
                                self?.hashWorkingQueue.remove(at: eLocation)
                            }
                            self?.schedule()
                        }
                    })
                }
            }

            if !(self?.shouldUpload!)! {return}
            while((self?.uploadPaddingQueue.count)! > 0 && (self?.uploadingQueue.count)! < (self?.uploadLimitCount)!) {
                guard let asset = self?.uploadPaddingQueue.first else{
                    return
                }
                let location = self?.uploadPaddingQueue.index(of: asset)
                if let eLocation = location{
                     self?.uploadPaddingQueue.remove(at: eLocation)
                }

                guard let manager = self?.sessionManager,let drive = self?.uuid else{
                    return
                }
                let model = WSUploadModel.init(asset: asset, manager: manager ,driveUUID: drive)
                guard let digest = asset.digest else{
                    return
                }

                if (self?.uploadedNetHashSet.contains(digest))! || (self?.uploadedLocalHashSet.contains(digest))! {
                    self?.uploadedQueue.append(model)
                    print("发现一个已上传的，直接跳过, error: \(String(describing: (self?.uploadErrorQueue.count)!)) finish:\(String(describing: (self?.uploadedQueue.count)!))")
                    defaultNotificationCenter().post(name: NSNotification.Name.Backup.AutoBackupCountChangeNotiKey, object: nil)
                    self?.schedule()

                }else {
                    self?.uploadingQueue.append(model)
                    self?.workingQueue.async {
                           self?.scheduleForUpload(model: model, useTimeStamp: false)
                    }
                }
            }
        }
    }
    
    
    // retry if exist
    func scheduleForUpload(model:WSUploadModel,useTimeStamp:Bool){
        self.workingQueue.async { [weak self] in
            model.start(useTimeStamp:useTimeStamp , callback: { [weak self](error, responseString) in
                self?.managerQueue.async {
                    if error != nil{
                        if error is BaseError{
                            let baseError = error as! BaseError
                            switch baseError.code {
                            case ErrorCode.Backup.BackupDirNotFound:
                                 self?.stop()
                                 self?.destroy()
                                 AppService.sharedInstance().rebuildAutoBackupManager()
                            case ErrorCode.Backup.BackupFileExist:
                                self?.scheduleForUpload(model: model, useTimeStamp: true)
                            default:
                                if !model.isRemoved!{
                                    self?.uploadErrorQueue.append(model)
                                    let location = self?.uploadingQueue.index(of: model)
                                    if let eLocation = location{
                                        self?.uploadingQueue.remove(at: eLocation)
                                    }
                                    print("上传失败 , error:\(String(describing: self?.uploadErrorQueue.count))  finish:\(String(describing: self?.uploadedQueue.count))")
                                }
                            }
                        }
                    }else{
                        print("上传成功 , error:\(String(describing: self?.uploadErrorQueue.count))  finish:\(String(describing: self?.uploadedQueue.count))")
                        if let location = self?.uploadingQueue.index(of: model){
                            self?.uploadingQueue.remove(at: location)
                        }
                        
                        self?.uploadedLocalHashSet.insert((model.asset?.digest!)!)
                        if !((self?.uploadedQueue.contains(model))!){
                            if !model.isRemoved! {
                                self?.uploadedQueue.append(model)
                                if let location = self?.uploadingQueue.index(of: model){
                                    self?.uploadingQueue.remove(at: location)
                                }
                                defaultNotificationCenter().post(name: NSNotification.Name.Backup.AutoBackupCountChangeNotiKey, object: nil)
                            }
                        }
                    }
                    self?.schedule()
                }
            })
        }
    }
    
    func stop(){
        self.shouldUpload = false
        AppService.sharedInstance().isStartingUpload = false
        //TODO: hash queue should stop?
        
        for model in self.uploadingQueue {
            model.cancel()
        }
       
        if let manager = sessionManager {
            manager.session.getAllTasks(completionHandler: { (uploadTasks) in
                uploadTasks.forEach { $0.cancel() }
            })
        }
        
         removeAll()
    }
    

    func addTask(_ asset: WSAsset?) {
        managerQueue.async(execute: { [weak self] in
            if asset != nil {
                self?.shouldNotify = true
                self?.needRetry = true
                if let anAsset = asset {
                    self?.hashwaitingQueue.append(anAsset)
                }
                self?.schedule()
            }
        })
    }
    
    func addTasks(_ assets: [WSAsset]?) {
        managerQueue.async(execute: { [weak self] in
            if assets?.count != nil {
                self?.shouldNotify = true
                self?.needRetry = true
                if let anAssets = assets {
                    self?.hashwaitingQueue.append(contentsOf: anAssets)
                }
                NotificationCenter.default.post(name: Notification.Name.Backup.AutoBackupCountChangeNotiKey, object: nil)
                self?.schedule()
            }
        })
    }

    func removeTask(_ rmAsset: WSAsset?){
        managerQueue.async(execute: { [weak self] in
            let assetId = rmAsset?.asset?.localIdentifier
            var asset: WSAsset?
            
            if let hashwaitingAsset = self?.hashwaitingQueue.first(where: {$0.asset?.localIdentifier == assetId}){
                asset = hashwaitingAsset
                self?.hashwaitingQueue.removeAll(where: { element in element == asset })
            }
            
            asset = nil

            if let uploadPaddingAsset = self?.uploadPaddingQueue.first(where: {$0.asset?.localIdentifier == assetId}){
                asset = uploadPaddingAsset
                self?.uploadPaddingQueue.removeAll(where: { element in element == asset })
            }

            var uploadModel: WSUploadModel?
            if let uploadingAsset = self?.uploadingQueue.first(where: {$0.asset?.asset?.localIdentifier == assetId}){
                uploadingAsset.isRemoved = true // remove
                uploadingAsset.cancel() //  not to uploadErrorQueue or uploadedQueue if removed
                uploadModel = uploadingAsset
                self?.uploadingQueue.removeAll(where: { element in element == uploadModel })
                self?.uploadErrorQueue.removeAll(where: { element in element == uploadModel })
            }
            
            uploadModel = nil
            
            if let uploadErrorAsset = self?.uploadErrorQueue.first(where: {$0.asset?.asset?.localIdentifier == assetId}){
                uploadModel = uploadErrorAsset
                self?.uploadErrorQueue.removeAll(where: { element in element == uploadModel })
            }
            
            uploadModel = nil
            
            if let uploadedAsset = self?.uploadedQueue.first(where: {$0.asset?.asset?.localIdentifier == assetId}){
                uploadModel = uploadedAsset
                self?.uploadedQueue.removeAll(where: { element in element == uploadModel })
            }
            
            NotificationCenter.default.post(name: Notification.Name.Backup.AutoBackupCountChangeNotiKey, object: nil)
            uploadModel = nil
        })
    }
    
    func removeTasks(_ assets: [WSAsset]?) {
        if let assets = assets{
            for asset in assets{
                self.removeTask(asset)
            }
        }
    }
    
    func  getAssetSha256(asset:WSAsset,callback:@escaping (_ error:Error?, _ sha256String:String?)->()){
        if asset.asset == nil {
            return callback(BaseError(localizedDescription: ErrorLocalizedDescription.Asset.AssetNotFound, code: ErrorCode.Asset.AssetNotFound),nil)
        }
        let localAsset = AppService.sharedInstance().assetService.getAsset(localId: asset.asset!.localIdentifier)
        if localAsset != nil{
                asset.digest = localAsset?.digest
            callback(nil, localAsset?.digest);
        }else{
           _ = asset.asset?.getSha256(callback: { (error, sha256) in
                if error != nil{
                  return callback(error, nil)
                }else{
                  asset.digest = sha256
                    DispatchQueue.global(qos: .default).async {
                        AppAssetService.saveAsset(localId: (asset.asset?.localIdentifier)!, digest: sha256!)
                    }
                    return callback(nil, sha256)
                }
            })
        }

    }
    
    lazy var uploadedNetHashSet = Set<String>.init()
    
    lazy var uploadedLocalHashSet = Set<String>.init()
    
    lazy var uploadedNetQueue =  Array<EntriesModel>.init()
    
    lazy var managerQueue: DispatchQueue = {
        let queue = DispatchQueue.init(label: "com.wisnuc.autoBackupManager.main")
        DispatchQueue.global(qos: .background).setTarget(queue: queue)
        return queue
    }()

    lazy var workingQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.wisnuc.autoBackupManager.workingQueue", attributes: .concurrent)
         DispatchQueue.global(qos: .userInitiated).setTarget(queue: queue)
        return queue
    }()
}

class WSUploadModel: NSObject {
    
    var shouldStop:Bool?
    
    var asset:WSAsset?
    
    var isRemoved:Bool? = false
    
    var requestFileID:PHImageRequestID?
    
    var manager:SessionManager?
    
    var driveUUID:String?
    init(asset:WSAsset,manager:SessionManager,driveUUID:String) {
        super.init()
        self.asset = asset
        self.manager = manager
        self.driveUUID = driveUUID
        self.shouldStop = false
    }
    
    func cancel() {
        self.shouldStop = false
        if requestFileID != nil {
            PHImageManager.default().cancelImageRequest(requestFileID!)
            requestFileID = PHInvalidImageRequestID
        }
        if manager != nil{
            manager?.session.getAllTasks(completionHandler: { (uploadTasks) in
                uploadTasks.forEach { $0.cancel() }
            })
        }
    }

    
    func start(useTimeStamp:Bool,callback:@escaping (_ error:Error?,_ responseString:String?)->()){
    /*
     * WISNUC API:UPLOAD A FILE
     */
    let invaildChars = ["/", "?", "<", ">", "\\", ":", "*", "|", "\""]
        self.requestFileID =  self.asset?.asset?.getFile(callBack: { [weak self] (error, filePath) in
            if error != nil{
                return callback(error,nil)
            }
            if (self?.shouldStop!)! {
                return callback(BaseError(localizedDescription: ErrorLocalizedDescription.Backup.BackupCancel, code: ErrorCode.Backup.BackupCancel), nil)
            }
            print("==========================开始上传==============================")
            let hashString = self?.asset?.digest
            let sizeNumber = FileTools.fileSizeAtPath(filePath: filePath!)
            let exestr = filePath?.lastPathComponent
            var fileName = PHAssetResource.assetResources(for: (self?.asset?.asset!)!).first?.originalFilename
            if fileName == nil {
                fileName = exestr
            }
            let  tempFileName = NSMutableString.init(string: fileName!)
            for i in 0..<tempFileName.length{
                if invaildChars.contains(((fileName! as NSString).substring(with: NSMakeRange(i, 1))) as String){
                    tempFileName.replaceCharacters(in: NSMakeRange(i, 1), with:"_" )
                }
            }
            fileName = tempFileName as String
            if(useTimeStamp) {
                fileName = "\(Date.init().timeIntervalSince1970)_\(String(describing: fileName))"
            }
            NSLog("filename :\(String(describing: fileName!))")
            var urlString:String?
            let requestHTTPHeaders = [kRequestAuthorizationKey:JWTTokenString(token: AppTokenManager.token!)]
            var mutableDic:Dictionary<String, Any>? = Dictionary<String, Any>.init()
            if AppUserService.currentUser?.isLocalLogin == nil {return}
            guard let driveUUID = self?.driveUUID else{
                Message.message(text: "上传错误：No drive")
                return
            }
            if AppNetworkService.networkState == .local {
                urlString = "\((RequestConfig.sharedInstance.baseURL!))/drives/\(driveUUID)/dirs/\(driveUUID)/entries/"
                mutableDic = nil
                mutableDic = Dictionary<String, Any>.init()
            }else {
                urlString = "\(kCloudAddr)\(kCloudCommonPipeUrl)"
                let requestUrl = "/drives/\(driveUUID)/dirs/\(driveUUID)/entries/"
                //                    let resource = requestUrl.toBase64()
                var manifestDic  = Dictionary<String, Any>.init()
                manifestDic[kRequestOpKey] = kRequestOpNewFileValue
                manifestDic[kRequestVerbKey] = RequestMethodValue.POST
                manifestDic[kRequestToNameKey] = fileName!
                manifestDic[kRequestUrlPathKey] = requestUrl
                manifestDic[kRequestImageSHA256Key]  = hashString!
                manifestDic[kRequestImageSizeKey] = NSNumber.init(value: sizeNumber)
                if let ctime = self?.fetchAssetCtime(){
                     manifestDic[kRequestBctimeKey] = NSNumber.init(value: ctime)
                }
                
                if let mtime = self?.fetchAssetMtime(){
                    manifestDic[kRequestBmtimeKey] = NSNumber.init(value: mtime)
                }
               
                let josnData = jsonToData(jsonDic: manifestDic as NSDictionary)
                
                let result = String.init(data: josnData!, encoding: String.Encoding.utf8)
                mutableDic!["manifest"] = result
            }
            var originalRequest: URLRequest?
            do {
                originalRequest = try URLRequest(url: URL.init(string: urlString!)! , method:.post, headers: requestHTTPHeaders)
                originalRequest?.timeoutInterval = TimeInterval(30)
                let encodedURLRequest = try  URLEncoding.default.encode(originalRequest!, with: nil)
                guard let exestr = exestr else{
                    return
                }
                var mimeType = "image/jpeg"
                if kVideoTypes.contains(where: {$0.caseInsensitiveCompare(exestr) == .orderedSame}) {
                   mimeType = "video/\(exestr.lowercased())"
                }
                self?.manager?.upload(multipartFormData: { (formData) in
                   
                    if AppNetworkService.networkState == .normal{
                        formData.append(URL.init(fileURLWithPath: filePath!), withName: fileName!, fileName: fileName!, mimeType: mimeType)
                    }else{
                        var dic = [kRequestImageSizeKey: sizeNumber,kRequestImageSHA256Key:hashString!, kRequestOpKey:kRequestOpNewFileValue] as [String : Any]
                        if let ctime = self?.fetchAssetCtime(){
                            dic[kRequestBctimeKey] = ctime
                        }
                        
                        if let mtime = self?.fetchAssetMtime(){
                             dic[kRequestBmtimeKey] = mtime
                        }
                       
                        if let jsonData =  jsonToData(jsonDictionary: dic){
                            let jsonString = String.init(data: jsonData, encoding: String.Encoding.utf8)
                            formData.append(URL.init(fileURLWithPath: filePath!), withName: fileName!, fileName: jsonString!, mimeType: mimeType)
                        }
                    }
                }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, with: encodedURLRequest, encodingCompletion: { (encodingResult) in
                    switch (encodingResult) {
                    // encodingResult success
                    case .success(let request, let streamingFromDisk, let streamFileURL):
                        print("\(streamingFromDisk) \(String(describing: streamFileURL))")
                        // upload progress closure
                        request.uploadProgress(closure: { (progress) in
                            print("upload progress: \(progress.fractionCompleted)")
                            // here you can send out to a delegate or via notifications the upload progress to interested parties
                        })
                        request.validate(statusCode: 200..<503)
                        // response handler
                        request.responseString(completionHandler: { response in
                            switch response.result {
                            case .success(let jsonString):
                                // do any parsing on your request's response if needed
                                if let data = jsonString.data(using: .utf8){
                                    do {
                                        guard let stringDic = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else{
                                            return callback(error,nil)
                                        }
                                        if let code = stringDic["code"] as? String{
                                             return callback(error,nil)
                                        }
                                    } catch {
                                        return callback(error,nil)
                                    }
                                }
                                callback(nil,jsonString)
                            case .failure(let error):
                                print(error)
                                return callback(error,nil)
                            }
                            
                            if let filePath = filePath{
                                do {
                                    try FileManager.default.removeItem(atPath: filePath)
                                }catch{
                                    print(error)
                                }
                            }
                          
                            if let streamFileURL = streamFileURL{
                                do {
                                    try FileManager.default.removeItem(at: streamFileURL)
                                }catch{
                                    print(error)
                                }
                            }
                        })
                    // encodingResult failure
                    case .failure(let error):
                    print(error )
                    return  callback(error,nil)
                    }
                })
            } catch {
                return callback(BaseError.init(localizedDescription: LocalizedString(forKey: "无法创建请求"), code: ErrorCode.Network.CannotBuidRequest),nil)
            }
        })
    }
    
    func fetchAssetCtime()->Int64? {
        if let netAsset = self.asset as? NetAsset{
            if let ctime = PhotoHelper.fetchPhotoTime(model: netAsset){
                let bctime = Int64(ctime*1000)
                return bctime
            }
        }else{
            if let localAsset = self.asset?.asset{
                if let ctime = localAsset.creationDate?.timeIntervalSince1970{
                   return Int64(ctime*1000)
                }
            }
        }
        return nil
    }
    
    func fetchAssetMtime()->Int64?{
        if let netAsset = self.asset as? NetAsset{
            if let mtime = netAsset.mtime{
                return Int64(mtime)
            }else{
                if let time = PhotoHelper.fetchPhotoTime(model: netAsset){
                    let bmtime = Int64(time*1000)
                    return bmtime
                }
            }
        }else{
            if let localAsset = self.asset?.asset{
                if let mtime = localAsset.modificationDate?.timeIntervalSince1970{
                    return Int64(mtime*1000)
                }
            }
        }
        return nil
    }
}
