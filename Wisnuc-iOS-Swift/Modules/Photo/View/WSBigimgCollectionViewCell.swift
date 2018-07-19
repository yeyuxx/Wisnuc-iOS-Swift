//
//  WSBigimgCollectionViewCell.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/7/11.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import MaterialComponents.MDCActivityIndicator
import Photos
import SDWebImage
import PhotosUI
import RxSwift
import AVKit
//---------------base preview---------------
class WSBasePreviewView: UIView {
    
    
    var wsAsset:WSAsset?
    
    var imageRequestID:PHImageRequestID?
    
    var singleTapCallback:(()->())?
    
    var sdDownloadToken:SDWebImageDownloadToken?
    
    func image()->UIImage?
    {return imageView.image}
    
    func loadNormalImage(asset:WSAsset){
        
    }
    
    func resetScale(){
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(singleTap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func singleTapAction(_ sender:UITapGestureRecognizer?){
        if let singleCallback =  singleTapCallback{
            singleCallback()
        }
    }
    
    lazy var indicator: MDCActivityIndicator = {
        let activityIndicator = MDCActivityIndicator.init()
        activityIndicator.center = self.center
        return activityIndicator
    }()
    
    lazy var imageView: UIImageView = {
        let imgView = UIImageView.init()
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        return imgView
    }()
    
    lazy var singleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(singleTapAction(_ :)))
        return tap
    }()
    
}

class WSPreviewImageAndGif: WSBasePreviewView {
    private var loadOK:Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
        self.scrollView.setZoomScale(1.0, animated: true)
        if (loadOK) {
            self.resetSubviewSize(self.wsAsset!.asset != nil ? self.wsAsset : self.imageView.image ?? nil)
        }
    }
    
    override func resetScale() {
        self.scrollView.zoomScale = 1
    }
    
    override func image() -> UIImage? {
        return self.imageView.image
    }
    
    func resumeGif(){
        let layer = self.imageView.layer
        if (layer.speed != 0.00000) {return}
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func pauseGif(){
        let layer = self.imageView.layer
        if (layer.speed == 0.00000) {return}
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func loadGifImage(asset:WSAsset){
        if asset.asset == nil {return}
        self.indicator.startAnimating()
        PHPhotoLibrary.requestOriginalImageData(for: asset.asset) { (data, info) in
            if !(info![PHImageResultIsDegradedKey] as! Bool){
                self.imageView.image = PHPhotoLibrary.animatedGIF(with: data!)
                self.resumeGif()
                self.resetSubviewSize(asset)
                self.indicator.stopAnimating()
            }
        }
    }
    
    override func loadNormalImage(asset:WSAsset){
        if (self.wsAsset?.asset != nil && self.imageRequestID != nil) {
            if self.imageRequestID! >= 0{
                PHCachingImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
        }
        
        if(self.sdDownloadToken != nil){
            SDWebImageDownloader.shared().cancel(self.sdDownloadToken)
            self.sdDownloadToken = nil
        }
        self.wsAsset = asset
        
        self.indicator.startAnimating()
        let scale = UIScreen.main.scale
        let width = MIN(x: __kWidth, y: CGFloat(kMaxImageWidth))
        var size = CGSize.zero
        if(self.wsAsset?.asset != nil){
            size = CGSize(width: width*scale, height: width*scale*CGFloat((asset.asset?.pixelHeight)!)/CGFloat((asset.asset?.pixelWidth)!))
        }
        
        self.imageRequestID = PHPhotoLibrary.requestImage(for: asset.asset, size: size, completion: { [weak self] (image, info) in
            self?.imageView.image = image;
            self?.resetSubviewSize(asset)
            if  !(info![PHImageResultIsDegradedKey] as! Bool){
                self?.indicator.stopAnimating()
                self?.loadOK = true
            }
        })
    }
    
    func loadImage(asset:WSAsset){
        self.imageView.image = nil
        if (self.wsAsset?.asset != nil && self.imageRequestID != nil) {
            if self.imageRequestID! >= 0{
                PHCachingImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
        }
        if(self.sdDownloadToken != nil){
            SDWebImageDownloader.shared().cancel(self.sdDownloadToken)
            self.sdDownloadToken = nil
        }
        self.wsAsset = asset
        self.indicator.startAnimating()
//        jy_weakify(self);
//        self.sdDownloadToken =  [WB_NetService getHighWebImageWithHash:[(WBAsset *)asset fmhash] completeBlock:^(NSError *error, UIImage *img) {
//            [weakSelf.indicator stopAnimating];
//            jy_strongify(weakSelf);
//            if(!self) return;
//            if (error) {
//            // TODO: Load Error Image
//            } else {
//            self->_loadOK = YES;
//            self.imageView.image = img;
//            if(asset.type == JYAssetTypeGIF) [self resumeGif];
//            [self resetSubviewSize:img];
//            }
//            self.sdDownloadToken = nil;
//            }];
        
    }

    @objc func doubleTapAction(_ sender:UITapGestureRecognizer?){
        var scale:CGFloat = 1
        if (scrollView.zoomScale != 3.0) {
            scale = 3
        } else {
            scale = 1
        }
        let zoomRect = self.zoomRect(scale: scale, center: (sender?.location(in: sender?.view))!)
        scrollView.zoom(to: zoomRect, animated: true)
    }
    
    func initUI(){
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.containerView)
        self.containerView.addSubview(self.imageView)
        self.addSubview(self.indicator)
        
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(doubleTapAction(_ :)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        self.singleTap.require(toFail: doubleTap)
    }
    
    func resetSubviewSize(_ value:Any?){
        if value == nil{
            return
        }
        self.containerView.frame = CGRect(x: 0, y: 0, width: __kWidth, height: 0)
        
        var frame:CGRect = CGRect.zero
        
        let orientation =  UIDevice.current.orientation
        
        var w:CGFloat = 0.0, h:CGFloat = 0.0
        
        if value is WSAsset{
            if let asset = (value as! WSAsset).asset{
                w = CGFloat(asset.pixelWidth)
                h = CGFloat(asset.pixelHeight)
            }
        }else{
            w = (value as! UIImage).size.width
            h = (value as! UIImage).size.height
        }
        
        let width = MIN(x: __kWidth, y: w)
        var orientationIsUpOrDown = true
        if (orientation == UIDeviceOrientation.landscapeLeft ||
            orientation == UIDeviceOrientation.landscapeRight) {
            orientationIsUpOrDown = false
            let height = MIN(x: __kHeight, y: h)
            frame.origin = CGPoint.zero
            frame.size.height = height
            let image = self.imageView.image
            
            let imageScale = (image?.size.width)!/(image?.size.height)!
            let screenScale = __kWidth/__kHeight
            if (imageScale > screenScale) {
                frame.size.width = CGFloat(floorf(Float(height * imageScale)))
                if (frame.size.width > __kWidth) {
                    frame.size.width = __kWidth;
                    frame.size.height = __kWidth / imageScale
                }
            } else {
                var imageWidth:CGFloat = CGFloat(floorf(Float(height * imageScale)))
                if (imageWidth < 1 || imageWidth.isNaN) {
                    //iCloud图片height为NaN
                    imageWidth = self.width
                }
                frame.size.width = imageWidth
            }
        }else{
            frame.origin = CGPoint.zero
            frame.size.width = width
            let image = self.imageView.image
            
            let imageScale = (image?.size.height)!/(image?.size.width)!
            let screenScale = __kHeight/__kWidth
            
            if (imageScale > screenScale) {
                //            frame.size.height = floorf(width * imageScale);
                frame.size.height = __kHeight;
                frame.size.width = CGFloat(floorf(Float(width * __kHeight / h)));
            } else {
                var height = floorf(Float(width * imageScale));
                if (height < 1 || height.isNaN) {
                    //iCloud图片height为NaN
                    height = Float(self.height)
                }
                
                frame.size.height = CGFloat(height)
            }
        }
        self.containerView.frame = frame
        
        var contentSize = CGSize.zero
        if (orientationIsUpOrDown) {
            contentSize = CGSize(width: width, height: MAX(x:__kHeight, y:frame.size.height))
            if (frame.size.height < self.height) {
                self.containerView.center = CGPoint(x: self.width/2, y: self.height/2)
            } else {
                self.containerView.frame = CGRect(origin: CGPoint(x: (self.width - frame.size.width)/2, y: 0), size: frame.size)
            }
        }else{
            contentSize = frame.size
            if (frame.size.width < self.width ||
                frame.size.height < self.height) {
                self.containerView.center = CGPoint(x: self.width/2, y: self.height/2)
            }
        }
        self.scrollView.contentSize = contentSize
        self.imageView.frame = self.containerView.bounds
        self.scrollView.scrollRectToVisible(self.bounds, animated: false)
    }
    
    func zoomRect(scale:CGFloat,center:CGPoint) ->CGRect{
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.scrollView.frame.size.height / scale
        zoomRect.size.width  = self.scrollView.frame.size.width  / scale
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / CGFloat.init(2.0))
        zoomRect.origin.y    = center.y - (zoomRect.size.height / CGFloat.init(2.0))
        return zoomRect
    }
    
    lazy var scrollView: UIScrollView = {
        let lazyScrollView = UIScrollView.init()
        lazyScrollView.frame = self.bounds
        lazyScrollView.maximumZoomScale = 3.0
        lazyScrollView.minimumZoomScale = 1.0
        lazyScrollView.isMultipleTouchEnabled = true
        lazyScrollView.delegate = self
        lazyScrollView.scrollsToTop = false
        lazyScrollView.showsHorizontalScrollIndicator = false
        lazyScrollView.showsVerticalScrollIndicator = false
        lazyScrollView.delaysContentTouches = false
        return lazyScrollView
    }()
    
    lazy var containerView: UIView = {
        let view = UIView.init()
        return view
    }()
}

extension WSPreviewImageAndGif:UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.width > scrollView.contentSize.width) ? (scrollView.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.height > scrollView.contentSize.height) ? (scrollView.height - scrollView.contentSize.height) * 0.5 : 0.0;
        self.containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.resumeGif()
    }
}

class WSPreviewLivePhoto: WSBasePreviewView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        lpView.frame = self.bounds
    }
    
    override func loadNormalImage(asset: WSAsset) {
        if (self.wsAsset?.asset != nil && self.imageRequestID != nil) {
            if self.imageRequestID! >= 0{
                PHCachingImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
        }
        
        self.wsAsset = asset
        self.indicator.startAnimating()
        let scale = UIScreen.main.scale
        let width = MIN(x:__kWidth, y:CGFloat(kMaxImageWidth))
        let size = CGSize(width: width*scale, height: width*scale*CGFloat((asset.asset?.pixelHeight)!)/CGFloat((asset.asset?.pixelWidth)!))
        self.imageRequestID = PHPhotoLibrary.requestImage(for: asset.asset, size: size, completion: { [weak self] (image, info) in
            self?.imageView.image = image;
            if !(info![PHImageResultIsDegradedKey] as! Bool){
                self?.indicator.stopAnimating()
            }
        })
    }
    
    func initUI(){
        self.addSubview(self.imageView)
        self.addSubview(self.lpView)
        self.addSubview(self.indicator)
    }
    
    func loadLivePhoto(asset:WSAsset){
      _ = PHPhotoLibrary.requestLivePhoto(for: asset.asset, completion: { (lv, info) in
                self.lpView.livePhoto = lv
                self.lpView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
        })
    }
    
    func stopPlayLivePhoto(){
        self.lpView.stopPlayback()
    }
    
    lazy var lpView: PHLivePhotoView = {
        let liveView = PHLivePhotoView.init(frame: self.bounds)
        liveView.contentMode = UIViewContentMode.scaleAspectFit
        return liveView
    }()
}

@objc protocol SWPreviewVideoPlayerDelegate {
    func playVideo(viewController:AVPlayerViewController)
}

class WSPreviewVideo: WSBasePreviewView {
    var disposeBag = DisposeBag()
    weak var delegate:SWPreviewVideoPlayerDelegate?
    private var hasObserverStatus:Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
     
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.playLayer?.frame = self.bounds
        self.playBtn.center = self.center
    }
    
    override func loadNormalImage(asset: WSAsset) {
        if (self.wsAsset?.asset != nil && self.imageRequestID != nil) {
            if self.imageRequestID! >= 0{
                PHCachingImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
        }
        self.wsAsset = asset
        
        if playLayer != nil {
            playLayer?.player = nil
            playLayer?.removeFromSuperlayer()
//            [_playLayer removeObserver:self forKeyPath:@"status"];
            hasObserverStatus = false
            playLayer = nil
        }
        
        self.imageView.image = nil;
        
        if !(asset.asset?.isLocal())! {
            self.initVideoLoadFailedFromiCloudUI()
            return
        }
        
        self.playBtn.isEnabled = true
        self.playBtn.isHidden = false
        self.icloudLoadFailedLabel.isHidden = true
        self.imageView.isHidden = false
        
        self.indicator.startAnimating()
        let scale = UIScreen.main.scale
        let width = MIN(x: __kWidth, y: CGFloat(kMaxImageWidth));
        let size = CGSize(width: width*scale, height: width*scale*CGFloat((asset.asset?.pixelHeight)!)/CGFloat((asset.asset?.pixelWidth)!))
        self.imageRequestID = PHPhotoLibrary.requestImage(for: asset.asset, size: size, completion: { [weak self] (image, info) in
            self?.imageView.image = image
            if !(info![PHImageResultIsDegradedKey] as! Bool){
                self?.indicator.stopAnimating()
            }
        })
    }
    func loadNetNormalImage(asset:WSAsset){
        if (self.wsAsset?.asset != nil && self.imageRequestID != nil) {
            if self.imageRequestID! >= 0{
                PHCachingImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
        }
        self.wsAsset = asset
        if ((playLayer) != nil) {
            playLayer?.player = nil
            playLayer?.removeFromSuperlayer()
//            [_playLayer removeObserver:self forKeyPath:@"status"];
            hasObserverStatus = false
            playLayer = nil
        }
        self.imageView.image = nil
        self.playBtn.isEnabled = true
        self.playBtn.isHidden = false
        self.icloudLoadFailedLabel.isHidden = true
        self.imageView.isHidden = false
        if AppNetworkService.networkState == .normal{
            Message.message(text: LocalizedString(forKey: "Operation not support"))
        }
//
        self.indicator.startAnimating()
//
//        jy_weakify(self);
//        [[FMMediaRamdomKeyAPI apiWithHash:[(WBAsset *)self.jyAsset fmhash]] startWithCompletionBlockWithSuccess:^(__kindof JYBaseRequest *request) {
//        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@media/random/%@", [JYRequestConfig sharedConfig].baseURL, request.responseJsonObject[@"key"]]];
//        if(!weakSelf) return;
//        dispatch_async(dispatch_get_main_queue(), ^{
//        jy_strongify(weakSelf);
//        if (!request.responseJsonObject) {
//        [strongSelf initVideoLoadFailedFromiCloudUI];
//        return;
//        }
//        AVPlayer *player = [AVPlayer playerWithURL:url];
//        [strongSelf.layer addSublayer:strongSelf.playLayer];
//        strongSelf.playLayer.player = player;
//        [strongSelf switchVideoStatus];
//        [strongSelf.playLayer addObserver:strongSelf forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//        _hasObserverStatus = YES;
//        [[NSNotificationCenter defaultCenter] addObserver:strongSelf selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
//        [[NSNotificationCenter defaultCenter] addObserver:strongSelf selector:@selector(playEnd:) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
//        [strongSelf.indicator stopAnimating];
//        });
//        } failure:^(__kindof JYBaseRequest *request) {
//        [SXLoadingView showAlertHUD:WBLocalizedString(@"play_failed", nil) duration:1];
//        [weakSelf.indicator stopAnimating];
//        }];
    }
    
    func initUI(){
        hasObserverStatus = false
        self.addSubview(self.imageView)
        self.addSubview(self.playBtn)
        self.addSubview(self.indicator)
        self.addSubview(self.icloudLoadFailedLabel)
    }
    
    func initVideoLoadFailedFromiCloudUI(){
        self.icloudLoadFailedLabel.isHidden = false
        self.playBtn.isEnabled = false
    }
    
    func haveLoadVideo()->Bool{
    return playLayer != nil ? true : false
    }
    
    func stopPlayVideo(){
        if (playLayer == nil) {
            return
        }
        self.playBtn.isHidden = false
        
    }
    
    
    
    func singleTapAction(){
      super.singleTapAction(nil)
    
    }
    
    func startPlayVideo(){
        if self.playLayer == nil {
            if self.wsAsset?.type == .Video{
                PHPhotoLibrary.requestVideo(for: self.wsAsset?.asset, completion: { (item, info) in
                    DispatchQueue.main.async {
                        if item == nil {
                            self.initVideoLoadFailedFromiCloudUI()
                            return
                        }
                        let player = AVPlayer.init(playerItem: item)
                        self.layer.addSublayer(self.playLayer!)
                        self.playLayer?.player = player
                        self.switchVideoStatus()
                        do {
                           try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                        }catch{
                            
                        }
                        self.playLayer?
                            .rx
                            .observe(AVPlayerItem.self, "status")
                            .subscribe(onNext: { [weak self] (newValue) in
                                
                                if let playerItem:AVPlayerItem = newValue {
                                    switch playerItem.status{
                                    case .readyToPlay : self?.imageView.isHidden = true
                                    case .unknown : Message.message(text: LocalizedString(forKey: "Error:Unkown error"))
                                    case .failed: Message.message(text: LocalizedString(forKey: "Error"))
                                        
                                    }
                                }
                            })
                            .disposed(by: self.disposeBag)
                        self.hasObserverStatus = true
                        defaultNotificationCenter()
                            .rx
                            .notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                            .subscribe(onNext: { (notification) in
                                self.playBtn.isHidden = false
                                self.imageView.isHidden = false
                                self.playLayer?.player?.seek(to: kCMTimeZero)
                            })
                          .disposed(by: self.disposeBag)
                    }
                })
            }else {
                if AppNetworkService.networkState == .normal{
                 Message.message(text: LocalizedString(forKey: "Operation not support"))
                }
            }
        } else {
            self.switchVideoStatus()
        }
    }

    func switchVideoStatus(){
        let player = self.playLayer?.player
        let stop = player?.currentItem?.currentTime
        let duration = player?.currentItem?.duration
        if player?.rate == 0.0 {
            self.playBtn.isHidden = true
            if  stop?().value == duration?.value  {
                player?.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1))
            }
    
            let playerViewController = AVPlayerViewController.init()
            playerViewController.delegate = self
            playerViewController.player = player
            if let delegateOK = self.delegate{
                delegateOK.playVideo(viewController: playerViewController)
            }
            playerViewController.player?.play()
            
        }
    }
    
    @objc func playBtnClick(_ sender:UIButton?){
        self.startPlayVideo()
    }
    
    
    lazy var icloudLoadFailedLabel: UILabel = {
        let str = NSMutableAttributedString.init()
        //创建图片附件
        let attach = NSTextAttachment.init()
        //        attach.image = GetImageWithName(@"videoLoadFailed");
        attach.bounds = CGRect(x: 0, y: -10, width: 30, height: 30)
        //创建属性字符串 通过图片附件
        let attrStr = NSAttributedString.init(attachment: attach)
        //把NSAttributedString添加到NSMutableAttributedString里面
        str.append(attrStr)
        
        let label = UILabel.init(frame: CGRect(x: 5, y: 70, width: 200, height: 35))
        label.font = UIFont.systemFont(ofSize: 12)
        label.attributedText = str
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var playBtn: UIButton = {
        let button = UIButton.init(frame: CGRect(origin: self.center, size: CGSize(width:80, height: 80)))
        button.setBackgroundImage(UIImage.init(named: "play2.png"), for: UIControlState.normal)
        button.addTarget(self, action: #selector(playBtnClick(_ :)), for: UIControlEvents.touchUpInside)
        self.bringSubview(toFront: button)
        return button
    }()
    
    lazy var playLayer: AVPlayerLayer? = {
        let player = AVPlayerLayer.init()
        player.frame = self.bounds
        return player
    }()
}

extension WSPreviewVideo:AVPlayerViewControllerDelegate{
    
}

class WSPreviewView: UIView {
    
    var showGif:Bool?
    var singleTapCallBack:(()->())?
    var showLivePhoto = false
    var model:WSAsset?{
        didSet{
            for view in self.subviews{
               view.removeFromSuperview()
            }
            switch model?.type {
            case .Image?,.GIF?:
                self.addSubview(self.imageGifView)
                if model is NetAsset {
                    return self.imageGifView.loadImage(asset:model!)
                }
                self.imageGifView.loadNormalImage(asset: model!)
            case .LivePhoto?:
                if (self.showLivePhoto) {
                    self.addSubview(self.livePhotoView)
                    self.livePhotoView.loadNormalImage(asset:model!)
                } else {
                    self.addSubview(self.imageGifView)
                    self.imageGifView.loadNormalImage(asset: model!)
                }
               case .Video?:
                self.addSubview(self.videoView)
                self.videoView.loadNormalImage(asset: model!)

            case .NetImage?:
                self.addSubview(self.imageGifView)
                self.imageGifView.loadImage(asset: model!)

            case .NetVideo? :
                self.addSubview(self.videoView)
                self.videoView.loadNetNormalImage(asset: model!)
            default:
                break
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch self.model?.type {
        case .Image?,.GIF?:
            self.imageGifView.frame = self.bounds
        case .LivePhoto?:
            if !self.showLivePhoto {
                 self.imageGifView.frame = self.bounds
            }else{
                self.livePhotoView.frame = self.bounds
            }
        case .Video?,.NetVideo?:
            self.videoView.frame = self.bounds
        default:
            break
        }
    }
    
    func imageViewFrame() -> CGRect{
        switch self.model?.type {
        case .Image?,.GIF?:
           return self.imageGifView.containerView.frame
        case .LivePhoto?:
            if !self.showLivePhoto {
                return self.imageGifView.containerView.frame
            }else{
                return self.livePhotoView.lpView.frame
            }
        case .Video?,.NetVideo?:
            return self.videoView.playLayer?.frame ?? CGRect.zero
        default:
            break
        }
        return CGRect.zero
    }
    
    func reload(){
        if self.showGif! &&
            self.model?.type == .GIF {
            if self.model is NetAsset {
                self.imageGifView.loadImage(asset: self.model!)
                return
            }
            self.imageGifView.loadGifImage(asset: self.model!)
        } else if self.showLivePhoto &&
            self.model?.type == .LivePhoto {
            self.livePhotoView.loadLivePhoto(asset: self.model!)
        }
    }

    func resumePlay(){
        if self.model?.type == .GIF {
            self.imageGifView.resumeGif()
        }
    }
    
    func pausePlay(){
        switch self.model?.type{
        case .GIF? :
            self.imageGifView.pauseGif()
        case .LivePhoto? :
            self.livePhotoView.stopPlayLivePhoto()
        case .Video?,.NetVideo?:
            self.videoView.stopPlayVideo()
        default: break
            
        }
    }
    
    func handlerEndDisplaying(){
        switch self.model?.type {
        case .GIF?:
            if  (self.imageGifView.imageView.image?.isKind(of: NSClassFromString("_UIAnimatedImage")!))!{
                self.imageGifView.loadNormalImage(asset: self.model!)
            }
        case .Video?:
            if self.videoView.haveLoadVideo() {
                self.videoView.loadNormalImage(asset: self.model!)
            }
        default:
            break
        }
    }
    
    func resetScale(){
      self.imageGifView.resetScale()
    }
    
    func image() ->UIImage?{
        if  self.model?.type == .Image {
            return self.imageGifView.imageView.image
        }
        return nil
    }

    lazy var imageGifView: WSPreviewImageAndGif = {
        let imageView = WSPreviewImageAndGif.init(frame: self.bounds)
        imageView.singleTapCallback = self.singleTapCallBack
        return imageView
    }()

    lazy var livePhotoView: WSPreviewLivePhoto = {
        let imageView = WSPreviewLivePhoto.init(frame: self.bounds)
        imageView.singleTapCallback = self.singleTapCallBack
        return imageView
    }()
    
    lazy var videoView: WSPreviewVideo = {
        let imageView = WSPreviewVideo.init(frame: self.bounds)
        imageView.singleTapCallback = self.singleTapCallBack
        return imageView
    }()
}

class WSBigimgCollectionViewCell: UICollectionViewCell {
    var singleTapCallBack:(()->())?
    var showGif:Bool = false
    var showLivePhoto:Bool = false
    var willDisplaying:Bool = false
    var model:WSAsset?{
        didSet{
            self.previewView.showGif = self.showGif
            self.previewView.showLivePhoto = self.showLivePhoto
            self.previewView.model = model
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(previewView)
        previewView.singleTapCallBack = { [weak self] in
            if let singleTapCallBack = self?.singleTapCallBack {
                singleTapCallBack()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetCellStatus(){
        self.previewView.resetScale()
    }
    
    func reloadGifLivePhoto(){
        if  self.willDisplaying {
            self.willDisplaying = false
            self.previewView.reload()
        } else {
            self.previewView.resumePlay()
        }
    }
    
    func pausePlay(){
        self.previewView.pausePlay()
    }
    
    lazy var previewView: WSPreviewView = {
        let view = WSPreviewView.init(frame: self.bounds)
        view.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleWidth.rawValue) | UInt8(UIViewAutoresizing.flexibleHeight.rawValue)))
        return view
    }()
}


