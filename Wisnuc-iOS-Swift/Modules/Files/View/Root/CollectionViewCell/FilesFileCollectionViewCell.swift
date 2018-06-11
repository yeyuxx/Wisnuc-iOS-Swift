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

typealias CellCallBack = (_ cell: MDCCollectionViewCell,_ button:UIButton) -> Void
typealias CellLongPressCallBack = ((_ cell:MDCCollectionViewCell) -> ())
class FilesFileCollectionViewCell: MDCCollectionViewCell {
    var longPressCallBack: CellLongPressCallBack?
    var cellCallBack:CellCallBack?
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
            make.size.equalTo(CGSize(width: (image?.size.width)! + 8, height: (image?.size.height)! + 20))
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
            make.size.equalTo(CGSize(width: 64, height: 64))
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        return imageViewx
    }()
}

