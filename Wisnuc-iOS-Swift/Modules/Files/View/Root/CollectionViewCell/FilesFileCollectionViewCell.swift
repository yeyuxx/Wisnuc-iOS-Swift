//
//  FilesFileCollectionViewCell.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/5/4.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import MaterialComponents
import Material
import Kingfisher

typealias CellCallBack = (_ cell: MDCCollectionViewCell,_ button:UIButton) -> Void
typealias CellLongPressCallBack = ((_ cell:MDCCollectionViewCell) -> ())
class FilesFileCollectionViewCell: MDCCollectionViewCell {
    var longPressCallBack: CellLongPressCallBack?
    var cellCallBack:CellCallBack?
    var image:UIImage?
    var isSelectModel: Bool?{
        didSet{
            if isSelectModel!{
                unselectAction()
            }else{
                normalAction()
            }
        }
    }
    var isSelect: Bool?{
        didSet{
            if isSelect!{
                selectAction()
            }else{
                unselectAction()
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.mainImageViewContentSize(isImage: false)
        self.mainImageView.image = nil
//        let normalImageName = FileTools.switchFilesFormatTypeNormalImage(type: FilesType.file, format:type)
//        self.mainImageView.image = UIImage.init(named: normalImageName)
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        setGestrue()
        self.contentView.addSubview(leftImageView)
        leftImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView.snp.left).offset(MarginsCloseWidth)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-MarginsCloseWidth)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    
        self.contentView.addSubview(moreButton)
        let image = UIImage.init(named: "more_gray_horizontal.png")
        moreButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView.snp.right).offset(-MarginsCloseWidth)
            make.centerY.equalTo(self.leftImageView.snp.centerY)
            make.size.equalTo(CGSize(width: (image?.size.width)! + 16, height: (image?.size.height)! + 40))
        }
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp.right).offset(MarginsCloseWidth)
            make.centerY.equalTo(leftImageView.snp.centerY)
            make.right.equalTo(moreButton.snp.left).offset(-MarginsWidth)
            make.height.equalTo(20)
        }
        
        self.contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView.snp.left)
            make.right.equalTo(self.contentView.snp.right)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-40)
            make.height.equalTo(1)
        }
        
        self.contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.centerY.equalTo(self.contentView.snp.centerY).offset(-20)
            make.size.equalTo(CGSize(width: self.width, height: self.height - lineView.height - 40))
        }
        
        self.contentView.addSubview(selectBackgroudImageView)
        selectBackgroudImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.centerY.equalTo(self.contentView.snp.centerY)
            make.size.equalTo(CGSize(width:self.contentView.width , height: self.contentView.height))
        }
        
        self.contentView.addSubview(selectImageView)
        selectImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.centerY.equalTo(self.contentView.snp.centerY)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
    }
    
    func mainImageViewContentSize(isImage:Bool){
        if isImage{
             mainImageView.snp.removeConstraints()
            mainImageView.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.contentView.snp.centerX)
                make.centerY.equalTo(self.contentView.snp.centerY).offset(-20)
                make.size.equalTo(CGSize(width: self.width, height: self.height - lineView.height - 40))
            }
        }else{
             mainImageView.snp.removeConstraints()
            mainImageView.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.contentView.snp.centerX)
                make.centerY.equalTo(self.contentView.snp.centerY).offset(-20)
                make.size.equalTo(CGSize(width: 64, height: 64))
            }
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(collectionView:UICollectionView,indexPath:IndexPath,type:FilesFormatType?,hash:String?,size:CGSize? = nil){
        let detailImageName = FileTools.switchFilesFormatType(type: FilesType.file, format: type)
        self.leftImageView.image = UIImage.init(named: detailImageName)
        self.mainImageViewContentSize(isImage: false)
        self.mainImageView.image = nil
        let normalImageName = FileTools.switchFilesFormatTypeNormalImage(type: FilesType.file, format:type)
        self.mainImageView.image = UIImage.init(named: normalImageName)

        if let type = type, let hash = hash{
            var imageSize = size
            if size == nil || size == CGSize.zero{
                imageSize = CGSize(width: self.contentView.width, height: self.contentView.height - lineView.height - 40)
            }
            if !kImageTypes.contains(type.rawValue){
                return
            }
            if let requestUrl =  self.requestImageUrl(size: imageSize!,hash: hash){
                ImageCache.default.retrieveImage(forKey: requestUrl.absoluteString, options: nil) { [weak self]
                    image, cacheType in
                    if let image = image {

//                        self?.mainImageView.image = nil
                        self?.mainImageViewContentSize(isImage: true)
//                        self?.model?.image = image
                        self?.mainImageView.image = image
                        self?.image = image
                        print("Get image \(image), cacheType: \(cacheType).")
                        //In this code snippet, the `cacheType` is .disk
                    } else {
                        print("Not exist in cache.")
                        let task = AppNetworkService.getThumbnail(hash: hash,size:imageSize!) { [weak self]  (error, image,reqUrl) in
                            if error == nil {
                                guard let absoluteString = reqUrl?.absoluteString else{
                                    return
                                }
                                if let image =  image{
                                    ImageCache.default.store(image,
                                                             original: nil,
                                                             forKey: absoluteString,
                                                             toDisk: true)
                                }
//                                 self?.mainImageView.image = nil
                                self?.mainImageViewContentSize(isImage: true)
//                                self?.model?.image = image
                                self?.mainImageView.image = image
                                self?.image = image
                            }else{
                                let normalImageName = FileTools.switchFilesFormatTypeNormalImage(type: FilesType.file, format:type)
                                self?.mainImageView.image = UIImage.init(named: normalImageName)
                            }
                        }
                        print(task as Any)
                    }
                }
            }
        }else{
            self.mainImageViewContentSize(isImage: false)
            self.mainImageView.image = nil
            let normalImageName = FileTools.switchFilesFormatTypeNormalImage(type: FilesType.file, format:type)
            self.mainImageView.image = UIImage.init(named: normalImageName)
        }
    }
    
    func requestImageUrl(size:CGSize,hash:String)->URL?{
        let detailURL = "media"
        let frameWidth = size.width
        let frameHeight = size.height
        let resource = "/media/\(hash)"
        let param = "\(kRequestImageAltKey)=\(kRequestImageThumbnailValue)&\(kRequestImageWidthKey)=\(String(describing: frameWidth))&\(kRequestImageHeightKey)=\(String(describing: frameHeight))&\(kRequestImageModifierKey)=\(kRequestImageCaretValue)&\(kRequestImageAutoOrientKey)=true"
        
        let params:[String:String] = [kRequestImageAltKey:kRequestImageThumbnailValue,kRequestImageWidthKey:String(describing: frameWidth),kRequestImageHeightKey:String(describing: frameHeight),kRequestImageModifierKey:kRequestImageCaretValue,kRequestImageAutoOrientKey:"true"]
        let dataDic = [kRequestUrlPathKey:resource,kRequestVerbKey:RequestMethodValue.GET,"params":params] as [String : Any]
        guard let data = jsonToData(jsonDic: dataDic as NSDictionary) else {
            return nil
        }
        
        guard let dataString = String.init(data: data, encoding: .utf8) else {
            return nil
        }
        
        guard let urlString = String.init(describing:"\(kCloudBaseURL)\(kCloudCommonPipeUrl)?data=\(dataString)").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        
        guard  let normalUrl = URL.init(string:urlString) else {
            return nil
        }
        //                req.addValue(dataString, forHTTPHeaderField: kRequestImageDataValue)
        guard let url = AppNetworkService.networkState == .local ? URL.init(string: "\(RequestConfig.sharedInstance.baseURL!)/\(detailURL)/\(hash)?\(param)") : normalUrl else {
            return nil
        }
        return url
    }
    
    func selectAction(){
        selectImageView.image = filesSelectImage
        selectBackgroudImageView.isHidden = false
        selectImageView.isHidden = false
    }
    
    func unselectAction(){
        selectImageView.image = filesUnSelectImage
        selectBackgroudImageView.isHidden = false
        selectImageView.isHidden = false
    }
    
    func normalAction(){
        selectImageView.isHidden = true
        selectBackgroudImageView.isHidden = true
    }
    
    func setGestrue(){
        let longPressGestrue = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(_ :)))
//        longPressGestrue.delegate = self
        self.addGestureRecognizer(longPressGestrue)
    }
    
    @objc func buttonClick(_ sender:UIButton){
        if self.cellCallBack != nil {
            self.cellCallBack!(self,sender)
        }
    }
    
    @objc func longPress(_ sender:UIGestureRecognizer){
        if sender.state == UIGestureRecognizerState.began{
         if longPressCallBack != nil{
                longPressCallBack!(self)
            }
        }
    }
    
    lazy var leftImageView: UIImageView = {
        let image = UIImage.init(named: "files_folder.png")
        let imageView = UIImageView.init(image: image)
        return imageView
    }()
    
    
    lazy var selectImageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    lazy var selectBackgroudImageView: UIImageView = {
        let image = UIImage.init(color: UIColor.black)
        let imageView = UIImageView.init(image: image)
        imageView.alpha = 0.12
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = DarkGrayColor
        label.font = MiddleTitleFont
        return label
    }()
    
    lazy var moreButton: IconButton = {
       let button = IconButton.init(image: Icon.moreHorizontal, tintColor: LightGrayColor)
        button.addTarget(self, action: #selector(buttonClick(_ :)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var lineView: UIView = {
        let view = UIView.init()
        view.backgroundColor = lightGrayBackgroudColor
        return view
    }()
    
    lazy var mainImageView: UIImageView = {
        let imageViewx = UIImageView.init()
        imageViewx.contentMode = UIViewContentMode.scaleAspectFill
        imageViewx.clipsToBounds = true
        return imageViewx
    }()
}

