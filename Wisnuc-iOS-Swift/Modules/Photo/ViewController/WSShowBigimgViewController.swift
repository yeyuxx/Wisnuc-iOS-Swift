//
//  WSShowBigimgViewController.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/7/11.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import PhotosUI
import Photos
import AVKit
import SnapKit
import RxSwift
import MapKit

enum  WSShowBigimgViewControllerState{
    case imageBrowser
    case info
}

@objc protocol WSShowBigImgViewControllerDelegate {
    func photoBrowser(browser:WSShowBigimgViewController, indexPath:IndexPath)
    func photoBrowser(browser:WSShowBigimgViewController, willDismiss indexPath:IndexPath) ->UIView?
}

class WSShowBigimgViewController: UIViewController {
    
    weak var delegate:WSShowBigImgViewControllerDelegate?
    var isLightContent = true
    var indexBeforeRotation:Int = 0
    var selectIndex:Int = 0
    var models:Array<Any>?
    var scaleImage:UIImage?
    var senderViewForAnimation:UIView?
    var isdraggingPhoto:Bool = false
    var currentPage:Int = 0
    var isFirstAppear:Bool = true
    var currentModelForRecord:Any?
    var disposeBag = DisposeBag()
    var appearResizableImageView:UIImageView?
    var mapView:MKMapView?
    var drive:String?
    var dir:String?
    var isHiddenNavigationBar = false{
        didSet{
            hiddenNavigationBarAction()
        }
    }
    var state:WSShowBigimgViewControllerState?{
        didSet{
            switch state {
            case .imageBrowser?:
                imageBrowserStateAction()
            case .info?:
                infoStateAction()
            default:
                break
            }
        }
    }
    private let cellReuseIdentifier = "WSBigimgCollectionViewCell"
    private let infoCellReuseIdentifier = "infoCellReuseIdentifierCell"
    init() {
        super.init(nibName: nil, bundle: nil)
        if self.responds(to: #selector(getter: self.automaticallyAdjustsScrollViewInsets) ){
            self.automaticallyAdjustsScrollViewInsets = false
            self.modalPresentationStyle = UIModalPresentationStyle.custom
            self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self.modalPresentationCapturesStatusBarAppearance = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.mapView?.removeFromSuperview()
        self.mapView = nil
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()

        print("show big image deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setState(.imageBrowser)
        basicSetting()
        self.view.addSubview(self.collectionView)
        collectionView.setContentOffset(CGPoint(x: __kWidth + CGFloat(kItemMargin)*CGFloat(indexBeforeRotation), y: 0), animated: false)
        initNavBtns()
        self.view.addSubview(self.infoTableView)
        self.view.addSubview(self.shareView)
        shareView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if (!isFirstAppear) {
            return
        }
        collectionView.setContentOffset(CGPoint(x: (__kWidth+CGFloat(kItemMargin))*CGFloat(indexBeforeRotation), y: 0), animated: false)
        self.performPresentAnimation()
        //开启和监听 设备旋转的通知（不开启的话，设备方向一直是UIInterfaceOrientationUnknown）
        if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDeviceOrientationChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return isLightContent ? .lightContent :.default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isLightContent = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!isFirstAppear) {
            return
        }
        isFirstAppear = false
        self.reloadCurrentCell()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override var prefersStatusBarHidden: Bool{
        return isHiddenNavigationBar
    }
    
    func setState(_ state:WSShowBigimgViewControllerState){
        self.state = state
    }
    
    func basicSetting(){
        ViewTools.automaticallyAdjustsScrollView(scrollView: collectionView, viewController: self)
        self.view.clipsToBounds = true
        self.view.alpha = 0
        currentPage = self.selectIndex+1
        indexBeforeRotation = self.selectIndex
        gestureSetting()
    }
    
    func initNavBtns(){
       naviView.addSubview(leftNaviButton)
        leftNaviButton.snp.makeConstraints { [weak self] (make) in
            make.centerY.equalTo((self?.naviView.snp.centerY)!).offset(10)
            make.left.equalTo((self?.naviView.snp.left)!).offset(16)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
       
        leftNaviButton.setEnlargeEdgeWithTop(5, right: 5, bottom: 5, left: 5)
        naviView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { [weak self] (make) in
            make.centerX.equalTo((self?.naviView.snp.centerX)!)
            make.centerY.equalTo((self?.naviView.snp.centerY)!).offset(10)
        }
        
        naviView.addSubview(moreNaviButton)
        
        moreNaviButton.snp.makeConstraints { [weak self] (make) in
            make.centerY.equalTo((self?.titleLabel.snp.centerY)!)
            make.right.equalTo((self?.naviView.snp.right)!).offset(-16)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        moreNaviButton.setEnlargeEdgeWithTop(5, right: 5, bottom: 5, left: 5)
        
        naviView.addSubview(shareNaviButton)
        shareNaviButton.snp.makeConstraints { [weak self] (make) in
            make.centerY.equalTo((self?.titleLabel.snp.centerY)!)
            make.right.equalTo((self?.moreNaviButton.snp.left)!).offset(-MarginsWidth)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        self.view.addSubview(naviView)
    }
    
    
    func displayNavigationBarAction(){
      
    }
    
    func hiddenNavigationBarAction(){
        setNeedsStatusBarAppearanceUpdate()
        let frame = isHiddenNavigationBar ? CGRect(x: 0, y: -naviView.height, width: naviView.width, height: naviView.height) : CGRect(x: 0, y: 0, width: naviView.width, height:naviView.height)
        UIView.animate(withDuration: 0.3, animations: {
            self.naviView.frame = frame
        })
    }
    
    func notificationSetting(){
        defaultNotificationCenter()
            .rx
            .notification(NSNotification.Name.UIApplicationDidChangeStatusBarOrientation)
            .subscribe(onNext: { (noti) in
               self.indexBeforeRotation = self.currentPage - 1
            })
            .disposed(by:disposeBag )
    }
    
    func imageBrowserStateAction(){
        setImageBrowserStateNavigationBar()
        self.collectionView.isScrollEnabled = true
        self.infoTableView.alpha = 0
        self.view.backgroundColor = .black
    }
    
    func deleteSelectPhotos(photos:[WSAsset]){
        var localAssets:Array<PHAsset> = Array.init()
        var netAssets:Array<NetAsset> = Array.init()
        for asset in photos{
            if asset is NetAsset{
                #warning("删除NAS照片")
                if let netAsset = asset as? NetAsset{
                    netAssets.append(netAsset)
                }
            }else{
                if let localAsset = asset.asset{
                    localAssets.append(localAsset)
                }
            }
        }
        
        if netAssets.count > 0{

        }
        
        if localAssets.count > 0{
            self.startActivityIndicator()
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(localAssets as NSFastEnumeration)
            }) { (finish, error) in
                if error != nil{
                    self.stopActivityIndicator()
                    print(error as Any)
                    return
                }
                if finish{
                    self.models?.removeAll(where: {($0 as? WSAsset)?.asset?.localIdentifier == localAssets.first?.localIdentifier })
                    self.titleLabel.text = "\(self.currentPage)/\(String(describing: (self.models?.count)!))"
                    self.stopActivityIndicator()
                    self.collectionView.reloadData()
                }
            }
        }
    }

    func infoStateAction(){
        self.collectionView.isScrollEnabled = false
        self.view.backgroundColor = .white
    }
    
    func setImageBrowserStateNavigationBar(){
    
    }
    
    func setInfoStateStateNavigationBar(){
    
    }
    
    func gestureSetting(){
        self.view.addGestureRecognizer(panGesture)
        let longGesture = UILongPressGestureRecognizer.init(target: self, action:#selector(longGestureRecognized(_ :)))
        self.view.addGestureRecognizer(longGesture)
    }
    
    func getImageFromView(view:UIView)->UIImage?{
            if view is UIImageView {
                return (view as! UIImageView).image
            }
            view.contentMode = .scaleAspectFill
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 2);
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
    }
    
    func getCurrentPageModel() -> Any?{
        let offset = self.collectionView.contentOffset
        
        let page = offset.x/(__kWidth+CGFloat(kItemMargin))
        if (ceilf(Float(page)) >= Float(self.models!.count) || page < 0) {
            return nil
        }
        let str = NSString.init(format: "%.0f", page)
        currentPage = str.integerValue + 1
        let model = self.models![currentPage-1]
        return model
    }
    
    func getCurrentPageRect()->CGRect{
        var frame = CGRect.zero
        let model = self.getCurrentPageModel()
         var w:CGFloat? = 0, h:CGFloat? = 0
        if model is WSAsset{
            let assetModel = model as! WSAsset
            if (assetModel.asset != nil) {
                w = CGFloat((assetModel.asset?.pixelWidth) ?? Int(__kWidth))
                h = CGFloat((assetModel.asset?.pixelHeight) ?? Int(__kHeight))
            } else if assetModel is NetAsset {
                w = CGFloat(((assetModel as! NetAsset).metadata?.w) ?? Float(__kWidth))
                h = CGFloat(((assetModel as! NetAsset).metadata?.h) ?? Float(__kHeight))
            } else {
                w = __kWidth
                h = __kHeight
            }
        }else if model is EntriesModel{
             let filesModel = model as! EntriesModel
            if let metadata = filesModel.metadata{
                w = metadata.w != nil ? CGFloat(metadata.w!) : __kWidth
                h = metadata.h != nil ? CGFloat(metadata.h!) : __kHeight
            }else{
                w = __kWidth
                h = __kHeight
            }
        }else{
            w = __kWidth
            h = __kHeight
        }
        let width = MIN(x: __kWidth, y: w!)
        frame.origin = CGPoint.zero
        frame.size.width = width
        
        let imageScale = h!/w!
        let screenScale = __kHeight/__kWidth
        
        if (imageScale > screenScale) {
            frame.size.height = __kHeight
            frame.size.width = CGFloat(floorf(Float(width * __kHeight / h!)))
        } else {
            var height = floorf(Float(width * imageScale))
            if (height < 1 || height.isNaN) {
                //iCloud图片height为NaN
                height = Float(self.view.height)
            }
            frame.size.height = CGFloat(height)
        }
        frame.origin.x = (__kWidth - frame.size.width)/2
        frame.origin.y = (__kHeight - frame.size.height)/2
        
        return frame
    }
    
    func reloadCurrentCell(){
        let model = self.getCurrentPageModel()
        if model is WSAsset{
            let assetModel = model as! WSAsset
            if (assetModel.type == .GIF ||
                assetModel.type == .LivePhoto) {
                let indexP = IndexPath.init(item: currentPage - 1, section: 0)
                let cell:WSBigimgCollectionViewCell? = collectionView.cellForItem(at: indexP) as? WSBigimgCollectionViewCell
                cell?.reloadGifLivePhoto()
            }
        }else{
            if let fileModel = model as? EntriesModel{
                if (fileModel.metadata?.type == "GIF") {
                    let indexP = IndexPath.init(item: currentPage - 1, section: 0)
                    let cell:WSBigimgCollectionViewCell? = collectionView.cellForItem(at: indexP) as? WSBigimgCollectionViewCell
                    cell?.reloadGifLivePhoto()
                }
            }
        }
        self.infoTableView.reloadData()
    }

    
    func handlerSingleTap(){
        isHiddenNavigationBar = !isHiddenNavigationBar
    }
    
    //查看大图进入动画
    func performPresentAnimation(){
        self.view.alpha = 0
        collectionView.alpha = 0
        let imageFromView = scaleImage != nil ? scaleImage : self.getImageFromView(view: senderViewForAnimation!)
    
        
        let senderViewOriginalFrame = senderViewForAnimation?.superview?.convert((senderViewForAnimation?.frame)!, to: self.view)
        
        let fadeView = UIView.init(frame: self.view.bounds)
        fadeView.backgroundColor = UIColor.clear
        let mainWindow = UIApplication.shared.keyWindow
        mainWindow?.addSubview(fadeView)
        let resizableImageView = UIImageView.init(image: imageFromView)
        resizableImageView.frame = senderViewOriginalFrame!
        resizableImageView.clipsToBounds = true
        resizableImageView.contentMode =  UIViewContentMode.scaleAspectFill
        resizableImageView.backgroundColor = UIColor.clear
        mainWindow?.addSubview(resizableImageView)
        let completion:()->Void =  {
            self.view.alpha = 1.0
            self.collectionView.alpha = 1.0
            resizableImageView.backgroundColor = UIColor.init(white: 1, alpha: 1)
            fadeView.removeFromSuperview()
            resizableImageView.removeFromSuperview()
        }
        // FIXME: net video animation error!
        let model = self.getCurrentPageModel()
        if model is EntriesModel{
            let filesModel = model as! EntriesModel
            if let type = filesModel.metadata?.type{
                if kVideoTypes.contains(where: {$0.caseInsensitiveCompare(type) == .orderedSame}){
                   return completion()
                }
            }
        }else if model is WSAsset{
            let assetModel = model as! WSAsset
            if assetModel.type == .Video{
                return completion()
            }
        }
       
        UIView.animate(withDuration: 0.3, animations: {
            fadeView.backgroundColor =  UIColor.black
        }) { (finished) in
            
        }
        
        let finalImageViewFrame = self.getCurrentPageRect()
        self.view.isOpaque = true
        
        UIView.animate(withDuration: 0.3, animations: {
            resizableImageView.frame = finalImageViewFrame
        }) { (finished) in
            completion()
        }
    }
    
   //查看大图退出动画
    func performDismissAnimation(){
        appearResizableImageView?.removeFromSuperview()
        let fadeAlpha = 1 - fabs(collectionView.top)/collectionView.frame.size.height
        let indexP = IndexPath.init(item: currentPage - 1, section: 0)
        let cell:WSBigimgCollectionViewCell? = collectionView.cellForItem(at: indexP) as? WSBigimgCollectionViewCell
        
        if cell == nil{
            self.dismiss(animated: true) {
                
            }
            return
        }
        let mainWindow = UIApplication.shared.keyWindow
        var frame = cell?.previewView.imageViewFrame() ?? CGRect.zero
        if cell?.previewView.imageViewFrame() == CGRect.zero{
            frame = CGRect(x: 0, y: 0, width: __kWidth, height: __kHeight)
        }
        let rect = cell?.previewView.convert(frame, to: self.view)
      
        
        if let delegateOK = self.delegate{
            senderViewForAnimation =  delegateOK.photoBrowser(browser: self, willDismiss: cell?.model is WSAsset ? ((cell?.model as! WSAsset).indexPath!) : ((cell?.model as! EntriesModel).indexPath!))
        }
        
        let senderViewOriginalFrame = senderViewForAnimation?.superview?.convert((senderViewForAnimation?.frame)! , to: self.view)
        if senderViewForAnimation == nil {
            return
        }
        
        var image:UIImage?
        if senderViewForAnimation is PhotoCollectionViewCell{
            image = (senderViewForAnimation as! PhotoCollectionViewCell).image
        }else if senderViewForAnimation is NewPhotoAlbumCollectionViewCell{
            image = (senderViewForAnimation as! NewPhotoAlbumCollectionViewCell).image
        }else{
            image = self.getImageFromView(view: senderViewForAnimation!)
        }
        
        let fadeView = UIView.init(frame: (mainWindow?.bounds)!)
        fadeView.backgroundColor = UIColor.black
        fadeView.alpha = fadeAlpha
        mainWindow?.addSubview(fadeView)
        
        appearResizableImageView = nil
        
        let resizableImageView = UIImageView.init(image: image)
        resizableImageView.frame = rect!
        resizableImageView.contentMode =  UIViewContentMode.scaleAspectFill
        resizableImageView.backgroundColor = UIColor.clear
        resizableImageView.clipsToBounds = true
        mainWindow?.addSubview(resizableImageView)
        self.view.isHidden = true
        
        let completion:()->() = { [weak self] in
            self?.senderViewForAnimation?.isHidden = false
            self?.senderViewForAnimation = nil
            self?.scaleImage = nil
            fadeView.removeFromSuperview()
            resizableImageView.removeFromSuperview()
            // Gesture
            mainWindow?.removeGestureRecognizer((self?.panGesture)!)
            // Controls
            NSObject.cancelPreviousPerformRequests(withTarget: self!)
            
            self?.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self?.presentingViewController?.dismiss(animated: false, completion: {
                
            })
        }

        UIView.animate(withDuration: 0.3, animations: {
            resizableImageView.frame = senderViewOriginalFrame!
            fadeView.alpha = 0
            self.view.backgroundColor = UIColor.clear
        }) { (finished) in
             completion()
        }
    }
    
    func shareAlert(){
        share()
    }
    
    //分享
    func share(){
        var array = Array<Any>.init()
        
        let indexP = IndexPath.init(item: currentPage - 1, section: 0)
        let cell:WSBigimgCollectionViewCell? = collectionView.cellForItem(at: indexP) as? WSBigimgCollectionViewCell
        
        if cell?.previewView.image() != nil{
            array.append((cell?.previewView.image())!)
        }
        
        let activityViewController =  UIActivityViewController.init(activityItems: array, applicationActivities: nil)
        self.present(activityViewController, animated: true) {
            
        }
        activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            if error != nil{
                
                SVProgressHUD.showError(withStatus: LocalizedString(forKey: "分享失败"))
                return
            }
            
            if completed {
                if activityType == UIActivityType.saveToCameraRoll {
                    SVProgressHUD.showSuccess(withStatus: LocalizedString(forKey: "已存入本地相册"))
                }else{
                    SVProgressHUD.showSuccess(withStatus: LocalizedString(forKey: "分享完成"))
                }
            }
            else{
                SVProgressHUD.showError(withStatus: LocalizedString(forKey: "分享未完成"))
            }
        }
    }
    
    func shareViewAction(){
        backView.backgroundColor = .black
        backView.alpha = 0
        self.view.addSubview(backView)
        self.view.bringSubview(toFront:shareView)
        UIView.animate(withDuration: 0.3, delay: 0.1, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.backView.alpha = 0.54
            self.shareView.frame = CGRect(x: 0, y: __kHeight - self.shareView.height, width: self.shareView.width, height: self.shareView.height)
        }) { (finish) in
           self.panGesture.isEnabled = false
        }
    }
    
    
    func infoBrowser(translatedPoint:CGPoint,gesture:UIPanGestureRecognizer){
       
    }
    
    func fetchAssetEXIFInfo(model:WSAsset?) ->[AnyHashable : Any]? {
        let fileUrl:URL = model?.asset?.getAssetPath() ?? URL.init(fileURLWithPath: "")
        let imageSource = CGImageSourceCreateWithURL(fileUrl as CFURL, nil)
        if imageSource != nil{
            let imageInfo = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil)
            if let dict = imageInfo as? [AnyHashable : Any] {
                return dict
            }
        }
        
        return nil
    }
    
    //设备方向改变的处理
    @objc func handleDeviceOrientationChange(_ notification: Notification) {
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        var isLandscape:Bool?
        switch deviceOrientation {
        case UIDeviceOrientation.landscapeLeft,UIDeviceOrientation.landscapeRight:
//                print("屏幕向左横置")
                isLandscape = true
            case UIDeviceOrientation.portraitUpsideDown,UIDeviceOrientation.portrait:
//                print("屏幕直立，上下顛倒")
                isLandscape = false
            default:
                print("无法辨识")
        }
        
        guard let scape = isLandscape else { return }
        if scape{
            self.view.frame = CGRect(x: 0, y: 0, width: __kWidth, height: __kHeight)
        }else{
            self.view.frame = CGRect(x: 0, y: 0, width: __kWidth, height: __kHeight)
        }
    }
    
    @objc func viewTap(_ sender:UIGestureRecognizer){
        isHiddenNavigationBar = !isHiddenNavigationBar
    }
    
    @objc func panGestureRecognized(_ gesture:UIPanGestureRecognizer){
        
        let scrollView = self.collectionView
        
        var  firstX:CGFloat = __kWidth/2, firstY:CGFloat = 0
        
        let viewHeight = __kHeight
        let viewHalfHeight = viewHeight/2
        firstY = viewHalfHeight
        
        let translatedPoint = gesture.translation(in: self.view)
//        self.infoBrowser(translatedPoint: translatedPoint,gesture)
        let absX = CGFloat(fabs(translatedPoint.x))
        let absY = CGFloat(fabs(translatedPoint.y)) // 设置滑动有效距离
        if max(absX, absY) < 5 {
            return
        }
        
        
        if absX > absY {
            if translatedPoint.x < 0 {
                if self.state ==  .info{
                    return
                }
                //向左滑动
            } else {
                //向右滑动
                if self.state ==  .info{
                    return
                }
            }
        } else if absY > absX {
            if translatedPoint.y < 0 {
                isdraggingPhoto = true
                self.setNeedsStatusBarAppearanceUpdate()

                print(translatedPoint.y)
                if scrollView.center.y <= scrollView.height/4 - scrollView.height/2{
                    if gesture.state == UIGestureRecognizerState.changed {
                        var point :CGFloat = -35
                        if translatedPoint.y > -35{
                            point = translatedPoint.y
                        }
                        UIView.animate(withDuration: 0.05, animations: {
                            scrollView.center = CGPoint(x: scrollView.center.x, y: scrollView.center.y+point)
                            self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom  - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                        }) { (finish) in
                            UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.curveEaseIn, animations: {
                                scrollView.center = CGPoint(x: scrollView.center.x, y: scrollView.center.y-point)
                                self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                            }, completion: { (finish) in
                                
                            })
                        }
                    }
                    return
                }
                
                if gesture.state == UIGestureRecognizerState.changed {
                    gesture.isEnabled = false
                    let rect = self.getCurrentPageRect()
                    if rect.height < __kHeight - 2{
                        self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom - (__kHeight - rect.height)/2 - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                    }else{
                        self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                    }
                    UIView.animate(withDuration: 0.3, delay: 0.1, options: UIView.AnimationOptions.curveEaseIn, animations: {
                        if rect.height < __kHeight - 2{
                            scrollView.center = CGPoint(x: scrollView.center.x, y: scrollView.height/4 - scrollView.height/2 + (__kHeight - rect.height)/2)
                            self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom - (__kHeight - rect.height)/2 - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                        }else{
                            scrollView.center = CGPoint(x: scrollView.center.x, y: scrollView.height/4 - scrollView.height/2)
                            self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom - 0.5, width: __kWidth, height: __kHeight - scrollView.height/4)
                        }
                        self.infoTableView.alpha = 1
                    }, completion: { (finish) in
                        gesture.isEnabled = true
                        self.state = .info
                    })
                }
                return
            } else {
                if scrollView.top <  -(__kHeight/4){
                    if gesture.state == UIGestureRecognizerState.changed {
                        gesture.isEnabled = false
                        UIView.animate(withDuration: 0.3, animations: {
                            scrollView.center = CGPoint(x: scrollView.center.x, y: __kHeight/2)
                            self.infoTableView.frame =  CGRect(x: 0, y: scrollView.bottom, width: __kWidth, height: __kHeight - scrollView.height/4)
                            self.infoTableView.alpha = 0
                        }) { (finsih) in
                            gesture.isEnabled = true
                            self.state = .imageBrowser
                        }
                    }
                    return
                }
                //向下滑动
            }
        }
        isdraggingPhoto = true
        self.setNeedsStatusBarAppearanceUpdate()
        let newTranslatedPoint = CGPoint(x: firstX+translatedPoint.x, y: firstY+translatedPoint.y)
        if gesture.state == UIGestureRecognizerState.changed {
            scrollView.center = newTranslatedPoint
            if appearResizableImageView != nil{
                appearResizableImageView!.center = newTranslatedPoint
            }
        }
        
        let newY = scrollView.center.y - viewHalfHeight
        let newAlpha =  1.0 - (fabsf(Float(newY))/Float(viewHeight))//abs(newY)/viewHeight * 1.8;
      
        self.view.isOpaque = true

        self.view.backgroundColor = UIColor.init(white: 0, alpha: CGFloat(newAlpha))
        
        // Gesture Ended
        if (gesture.state == UIGestureRecognizerState.ended) {
            scrollView.isScrollEnabled = true
            let moveDismissDistance:CGFloat = 30
            if (scrollView.center.y > viewHalfHeight+moveDismissDistance || scrollView.center.y < viewHalfHeight-moveDismissDistance) {
                if ((senderViewForAnimation) != nil) {
                    self.performDismissAnimation()
                    return
                }
                
                let finalX:CGFloat  = firstX
                var finalY:CGFloat  = firstX
                
                let windowsHeigt:CGFloat  = self.view.height
                
                if(scrollView.center.y > viewHalfHeight+30){ // swipe down
                    finalY = windowsHeigt*2
                }else{ // swipe up
                    finalY = -viewHalfHeight
                }
                
                let animationDuration:CGFloat = 0.35
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(TimeInterval(animationDuration))
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                UIView.setAnimationDelegate(self)
                scrollView.center = CGPoint(x: finalX, y: finalY)
                self.view.backgroundColor = UIColor.init(white: 0, alpha: CGFloat(newAlpha))
                UIView.commitAnimations()

                self.perform(#selector(back), with: self, afterDelay: TimeInterval(animationDuration))
            }
            else // Continue Showing View
            {
                isdraggingPhoto = false
                self.setNeedsStatusBarAppearanceUpdate()
                
                self.view.backgroundColor = UIColor.init(white: 0, alpha: 1)
                
                let velocityY:CGFloat = (0.35*gesture.velocity(in: self.view).y);
                
                let finalX:CGFloat = firstX
                let finalY:CGFloat = viewHalfHeight
                
                let animationDuration  = abs((velocityY)*0.0002)+0.2
                
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(TimeInterval(animationDuration))
                UIView.setAnimationCurve(UIViewAnimationCurve.easeOut)
                UIView.setAnimationDelegate(self)
                scrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
            }
        }
    }
    
    @objc func longGestureRecognized(_ sender:UILongPressGestureRecognizer){
        if (sender.state == UIGestureRecognizerState.began) {
           shareAlert()
        }
    }
    
    @objc func back(){
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func readyToShare(){
        self.shareViewAction()
    }
    
    @objc func doneButtonPressed(){
       self.performDismissAnimation()
    }
    
    @objc func shareItemTap(_ sender:UIBarButtonItem){
        
    }
    
    @objc func moreItemTap(_ sender:UIButton){
        let moveBottomVC = FilesFilesBottomSheetContentTableViewController.init(style: UITableViewStyle.plain, type: FilesBottomSheetContentType.selectMore)
        moveBottomVC.delegate = self
        let bottomSheet = AppBottomSheetController.init(contentViewController: moveBottomVC)
        bottomSheet.trackingScrollView = moveBottomVC.tableView
        if let model = getCurrentPageModel() as? WSAsset{
            moveBottomVC.assetModelArray = [model]
        }else if let model = getCurrentPageModel() as? EntriesModel{
            moveBottomVC.filesModelArray = [model]
        }
        self.present(bottomSheet, animated: true, completion: {
        })
    }
    
    @objc func backViewTap(_ sender:UITapGestureRecognizer?){
        UIView.animate(withDuration: 0.3, delay: 0.1, options: UIViewAnimationOptions.curveEaseOut, animations: {
             self.shareView.frame = CGRect(x: 0, y: __kHeight, width: __kWidth, height: 266)
             self.backView.alpha = 0
        }) { (finish) in
             self.backView.removeFromSuperview()
             self.panGesture.isEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    lazy var collectionViewlayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.minimumLineSpacing = CGFloat(kItemMargin);
        layout.sectionInset = UIEdgeInsetsMake(0, CGFloat(kItemMargin/2), 0, CGFloat(kItemMargin/2));
        layout.itemSize = self.view.bounds.size
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: collectionViewlayout)
        collection.register(WSBigimgCollectionViewCell.self, forCellWithReuseIdentifier:cellReuseIdentifier)
        
        collection.dataSource = self
        collection.delegate = self
        collection.isPagingEnabled = true
        collection.backgroundColor = UIColor.clear
        
        collection.setCollectionViewLayout(collectionViewlayout, animated: true)
        collection.frame = CGRect(x: -CGFloat(kItemMargin)/2, y: 0, width: __kWidth+CGFloat(kItemMargin), height: __kHeight)
        return collection
    }()
    
    lazy var infoTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: __kHeight, width: __kWidth, height: __kHeight), style: UITableViewStyle.grouped)
        tableView.register(UINib.init(nibName: StringExtension.classNameAsString(targetClass: BigPhotoInfoTableViewCell.self), bundle: nil), forCellReuseIdentifier: infoCellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isPagingEnabled = true
        tableView.bounces = false
        tableView.alpha = 0
        return tableView
    }()
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognized(_ :)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.white
        let font = UIFont.mdc_standardFont(forMaterialTextStyle: MDCFontTextStyle.body1)
        label.font = font.withSize(20)
        label.textAlignment = NSTextAlignment.center
        return label
    }()

    lazy var naviView: UIView = {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: __kWidth, height: 64))
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var leftNaviButton: UIButton = {
        let button = UIButton.init()
        button.setImage(MDCIcons.imageFor_ic_arrow_back()?.byTintColor(UIColor.white), for: UIControlState.normal)
        button.addTarget(self, action: #selector(doneButtonPressed), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var moreNaviButton: UIButton = {
        let button  = UIButton.init()
        button.setImage(MDCIcons.imageFor_ic_more_horiz()?.byTintColor(.white), for: UIControlState.normal)
        button.addTarget(self, action: #selector(moreItemTap(_:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var shareNaviButton: UIButton = {
        let button  = UIButton.init()
        button.setImage(UIImage.init(named: "share_white.png"), for: UIControlState.normal)
        button.addTarget(self, action: #selector(readyToShare), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var backView: UIView = {
        let view  = UIView.init(frame: CGRect(x: 0, y: 0, width: __kWidth, height: __kHeight))
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(backViewTap(_ :)))
        view.addGestureRecognizer(tap)
        return view
    }()

    lazy var shareView = PhotoShareView.init(frame: CGRect(x: 0, y: __kHeight, width: __kWidth, height: 266))

    lazy var describeTextField = UITextField.init()
}

extension WSShowBigimgViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.models!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:WSBigimgCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! WSBigimgCollectionViewCell
        let model = self.models![indexPath.item]
        cell.previewView.videoView.delegate = self
        
        cell.showGif = true
        cell.showLivePhoto = true
        cell.drive = self.drive
        cell.dir = self.dir
        cell.model = model
        
        cell.loadImageCompleteCallback = { [weak self] in
            self?.appearResizableImageView?.removeFromSuperview()
            self?.appearResizableImageView = nil
        }
        cell.singleTapCallBack = { [weak self] in
            self?.handlerSingleTap()
        };
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as! WSBigimgCollectionViewCell).previewView.resetScale()
        (cell as! WSBigimgCollectionViewCell).willDisplaying = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as! WSBigimgCollectionViewCell).previewView.handlerEndDisplaying()
    }
}

extension WSShowBigimgViewController:UIScrollViewDelegate{
//    照片滑动
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView  {
            if scrollView.center.y <= scrollView.height/4 - scrollView.height/2{
                return
            }
            let m =  self.getCurrentPageModel()
            if m == nil{
                 return
            }
            if m is WSAsset{
                if currentModelForRecord is WSAsset{
                    if m as! WSAsset == currentModelForRecord as! WSAsset{
                      return
                    }
                }
            }else{
                if currentModelForRecord is EntriesModel{
                    if (m as! EntriesModel).hash == (currentModelForRecord as! EntriesModel).hash{
                        return
                    }
                }
            }

            currentModelForRecord = m
            //改变导航标题
            if self.delegate != nil && !isFirstAppear{
                var indexPath:IndexPath?
                if m is WSAsset{
                    indexPath = (m as! WSAsset).indexPath
                }else if m is EntriesModel{
                    indexPath = (m as! EntriesModel).indexPath
                }
                self.delegate?.photoBrowser(browser: self, indexPath: indexPath!)
            }
            //!!!!!: change Title
            titleLabel.text = "\(currentPage)/\(String(describing: (self.models?.count)!))"
            if m is WSAsset{
                let cell = collectionView.cellForItem(at: IndexPath.init(item: currentPage-1 , section: 0))
                (cell as? WSBigimgCollectionViewCell)?.removeContent()
                let assetModel = m as! WSAsset
                if (assetModel.type == .GIF ||
                    assetModel.type == .LivePhoto ||
                    assetModel.type == .Video || assetModel.type == .NetVideo) {
                    
                    if  cell != nil{
                        (cell as? WSBigimgCollectionViewCell)?.pausePlay()
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         self.reloadCurrentCell()
    }
}

extension WSShowBigimgViewController:SWPreviewVideoPlayerDelegate{
    func playVideo(viewController: AVPlayerViewController) {
        self.present(viewController, animated: true) {
            
        }
        
        let indexP = IndexPath.init(item: currentPage - 1, section: 0)
        let  cell =  collectionView.cellForItem(at: indexP)
        if cell != nil {
            (cell as! WSBigimgCollectionViewCell).previewView.videoView.stopPlayVideo()
        }
    }
}

//向上滑动详情信息
extension WSShowBigimgViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:BigPhotoInfoTableViewCell = tableView.dequeueReusableCell(withIdentifier: infoCellReuseIdentifier, for: indexPath) as! BigPhotoInfoTableViewCell
        tableView.separatorStyle = .none
        let model = getCurrentPageModel()

        switch indexPath.row {
        case 0:
            cell.leftImageView.image = UIImage.init(named: "calendar_gray.png")
            var mtime:TimeInterval = 0
            if model is WSAsset{
            let assetModel = model as! WSAsset
                mtime = model is NetAsset ? (model as! NetAsset).mtime ?? 0 : ((assetModel.asset?.creationDate?.timeIntervalSince1970 ?? 0)*1000 )
            }else if model is EntriesModel{
               let filesModel = model as! EntriesModel
                if let date = filesModel.metadata?.date{
                    mtime = (TimeTools.dateTimeInterval(date) ?? 0)*1000
                }else
                if let time = filesModel.mtime{
                    mtime = TimeInterval(time)
                }
            }
            
            cell.titleLabel.text =  TimeTools.timeString(TimeInterval(mtime)/1000)
            cell.detailLabel.text = "\(TimeTools.weekDay(TimeInterval(mtime)/1000)) \(TimeTools.timeHourMinuteString(TimeInterval(mtime)/1000))"
        case 1:
            cell.leftImageView.image = UIImage.init(named: "photo_gray_info.png")
            if model is WSAsset{
                if model is NetAsset{
                    cell.titleLabel.text = (model as! NetAsset).name  ?? ""
                }else{
                    if let asset = (model as! WSAsset).asset{
                        cell.titleLabel.text = asset.getName()
                    }
                }
            }else{
                if let fileModel = model as? EntriesModel{
                    if let name = fileModel.name{
                        cell.titleLabel.text = name
                    }
                }
            }
            
            var infoArray:Array<String> = Array.init()
            if model is WSAsset{
                if let exifDic = self.fetchAssetEXIFInfo(model: model as? WSAsset){
                    if  let pixelWidthNumber = exifDic[kCGImagePropertyPixelWidth] as? NSNumber,let pixelHeightNumber = exifDic[kCGImagePropertyPixelHeight] as? NSNumber{
                        let pixelWidth = pixelWidthNumber.stringValue
                        let pixelHeight = pixelHeightNumber.stringValue
                        let pixel = "\(pixelWidth)x\(pixelHeight)"
                        infoArray.append(pixel)
                    }else if let pixelWidthNumber = exifDic["PixelWidth"] as? NSNumber,let pixelHeightNumber = exifDic["PixelHeight"] as? NSNumber{
                        let pixelWidth = pixelWidthNumber.stringValue
                        let pixelHeight = pixelHeightNumber.stringValue
                        let pixel = "\(pixelWidth)x\(pixelHeight)"
                        infoArray.append(pixel)
                    }
                }
                
                if let size = model is NetAsset ? sizeString((model as! NetAsset).size ?? 0) : (model as! WSAsset).asset?.getSizeString(){
                    infoArray.append(size)
                }
            }else{
                if  let filesModel = model as? EntriesModel{
                    if let pixelWidth = filesModel.metadata?.w,let pixelHeight = filesModel.metadata?.h{
                        let pixel = "\(pixelWidth)x\(pixelHeight)"
                        infoArray.append(pixel)
                    }
                    let filesSize = filesModel.size
                    let size = sizeString(filesSize ?? 0)
                    infoArray.append(size)
                }
            }
            cell.detailLabel.text = infoArray.joined(separator: "  ")
        case 2:
            cell.leftImageView.image = UIImage.init(named: "lens_gary.png")
            var infoArray:Array<String> = Array.init()
            if model is WSAsset{
                if let exifDic = self.fetchAssetEXIFInfo(model: model as? WSAsset){
                    if  let imageTIFFDictionary = exifDic[kCGImagePropertyTIFFDictionary] as? [AnyHashable : Any]{
                        if let imageTIFFModel = imageTIFFDictionary[kCGImagePropertyTIFFModel] as? String{
                            cell.titleLabel.text = imageTIFFModel
                        }
                        
                        if  let imageExifDictionary = exifDic[kCGImagePropertyExifDictionary] as? [AnyHashable : Any]{
                            if  let imageFNumber = imageExifDictionary[kCGImagePropertyExifFNumber] as? NSNumber{
                                let imageFNumberString = "f/\(imageFNumber.stringValue)"
                                infoArray.append(imageFNumberString)
                            }
                            
                            if  let imageExposureTime = imageExifDictionary[kCGImagePropertyExifExposureTime] as? NSNumber{
                                var exposureTimeString = ""
                                if imageExposureTime.floatValue < 1.00000{
                                    exposureTimeString = "1/\(String.init(format: "%.2f", imageExposureTime.floatValue*100))"
                                }else{
                                    exposureTimeString = "\(String.init(format: "%.f", imageExposureTime.floatValue))s"
                                }
                                infoArray.append(exposureTimeString)
                            }
                            
                            if  let imageFocalLength = imageExifDictionary[kCGImagePropertyExifFocalLength] as? NSNumber{
                                infoArray.append("\(imageFocalLength.stringValue)mm")
                            }
                            
                            if  let imageISOSpeedRatings = imageExifDictionary[kCGImagePropertyExifISOSpeedRatings] as? [NSNumber]{
                                if imageISOSpeedRatings.count > 0{
                                    infoArray.append("ISO \(imageISOSpeedRatings[0].stringValue)")
                                }
                            }
                        }
                    }
                }
            }
           cell.detailLabel.text = infoArray.joined(separator: "  ")
        case 3:
            cell.leftImageView.image = UIImage.init(named: "location_gary.png")
            var infoArray:Array<String> = Array.init()
            if model is WSAsset{
                if let exifDic = self.fetchAssetEXIFInfo(model: model as? WSAsset){
                    if  let imageGPSDictionary = exifDic[kCGImagePropertyGPSDictionary] as? [AnyHashable : Any]{
                        //                    print(imageGPSDictionary)
                        if let imageLatitude = imageGPSDictionary[kCGImagePropertyGPSLatitude] as? NSNumber,let imageLongitude = imageGPSDictionary[kCGImagePropertyGPSLongitude] as? NSNumber{
                            // 创建经纬度
                            let location = CLLocation(latitude: imageLatitude.doubleValue, longitude: imageLongitude.doubleValue)
                            let cLGeocoder = CLGeocoder.init()
                            cLGeocoder.reverseGeocodeLocation(location) {(placemarks, error) in
                                if let  placemarks = placemarks{
                                    if  placemarks.count > 0{
                                        var locationArray:Array<String> = Array.init()
                                        let place = placemarks[0]
                                        if  let country = place.country{
                                            locationArray.append(country)
                                        }
                                        
                                        if  let locality = place.locality{
                                            locationArray.append(locality)
                                        }
                                        
                                        if  let subLocality = place.subLocality{
                                            locationArray.append(subLocality)
                                        }
                                        
                                        cell.titleLabel.text = locationArray.joined(separator: "")
                                    }
                                }
                            }
                            
                            let centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(imageLatitude.doubleValue, imageLongitude.doubleValue)
                            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
                            let region: MKCoordinateRegion = MKCoordinateRegionMake(centerCoordinate, span)
                            if self.mapView == nil{
                                self.mapView = MKMapView.init()
                            }
                            mapView?.region = region
                            mapView?.showsTraffic = true
                            let pin = MapPin.init(coordinate: centerCoordinate)
                            mapView?.addAnnotation(pin)
                            let latitude = String.init(format: "%.3f", imageLatitude.floatValue)
                            let longitude = String.init(format: "%.3f", imageLongitude.floatValue)
                            let coordinate = "\(latitude),\(longitude)"
                            infoArray.append(coordinate)
                        }
                    }
                }
            }
            cell.detailLabel.text = infoArray.joined(separator: "  ")
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 154
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.zero)
        self.describeTextField.frame = CGRect(x: MarginsWidth, y: 0, width: __kWidth - MarginsWidth*2, height: 56 - 1)
        self.describeTextField.placeholder = LocalizedString(forKey: "添加说明")
        let view = UIView.init(frame: CGRect(x: 0, y: 56 - 1, width: __kWidth, height: 1))
        view.backgroundColor = Gray12Color
        headerView.backgroundColor = .white
        headerView.addSubview(self.describeTextField)
        headerView.addSubview(view)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let model = getCurrentPageModel()
        if model is WSAsset{
            if let exifDic = self.fetchAssetEXIFInfo(model: model as? WSAsset){
                if  exifDic[kCGImagePropertyGPSDictionary] != nil {
                    if self.mapView == nil{
                        self.mapView = MKMapView.init()
                    }
                    self.mapView?.isZoomEnabled = false
                    self.mapView?.isScrollEnabled = false
                    self.mapView?.isRotateEnabled = false
                    self.mapView?.delegate = self
                }else{
                    self.mapView = nil
                }
            }
        }
        return self.mapView
    }
}

extension WSShowBigimgViewController:MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        print("AnnotationViews were added.")
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("AnnotationView's calloutView was tapped.")
    }
}

extension WSShowBigimgViewController:PhotoShareViewDelegate{
    func shareImages() -> [UIImage]? {
        return nil
    }
    
    func shareImage() -> UIImage? {
     
        let indexP = IndexPath.init(item: currentPage - 1, section: 0)
        let cell:WSBigimgCollectionViewCell? = collectionView.cellForItem(at: indexP) as? WSBigimgCollectionViewCell

        return  cell?.previewView.image()
    }
    
    func didEndShare(){
        self.backViewTap(nil)
    }
}

extension WSShowBigimgViewController:FilesBottomSheetContentVCDelegate{
    func filesBottomSheetContentTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath,models:[Any]?){
        if let models = models as? [WSAsset]{
            let title = "\(models.count) 个照片\(LocalizedString(forKey: "将被删除"))"
            alertController(title: title, message: LocalizedString(forKey: "照片删除后将无法恢复"), cancelActionTitle: LocalizedString(forKey: "Cancel"), okActionTitle: LocalizedString(forKey: "Confirm"), okActionHandler: { (AlertAction1) in
                self.deleteSelectPhotos(photos: models)
            }) { (AlertAction2) in
                
            }
        }
    }
    
    func filesBottomSheetContentTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, model: Any?) {
        
    }
    
    func filesBottomSheetContentInfoButtonTap(_ sender: UIButton, model: Any) {
        
    }
    
    func filesBottomSheetContentSwitch(_ sender: UISwitch, model: Any) {
        
    }
 
}

//地图标记
class MapPin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
