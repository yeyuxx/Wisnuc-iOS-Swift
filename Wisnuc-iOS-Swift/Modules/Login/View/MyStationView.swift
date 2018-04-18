//
//  MyStationView.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/4/12.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit

enum StationButtonType :String {
    case diskError = "disk_error"
    case normal = "normal"
    case offline = "offline"
    case local = "local"
    case poweroff = "power_off"
    case addNew = "add_new"
    case checking = "checking"
}

private let Width_Space:CGFloat  = MarginsCloseWidth
private let Height_Space:CGFloat  = MarginsCloseWidth
private let ViewWidth:CGFloat  = (__kWidth - MarginsWidth * 2 - MarginsCloseWidth)/2
private let ViewHeight:CGFloat  = (__kWidth - MarginsWidth * 2 - MarginsCloseWidth)/2
private let Start_X:CGFloat  = 0
private var Start_Y:CGFloat = 0
private let ButtonWidth:CGFloat  = 64
private let ButtonHeight:CGFloat  = 64
private let IconWidth:CGFloat  = 18
private let IconHeight:CGFloat  = 18

private let StationViewInnerImageViewTop_Width_Space:CGFloat = 20
private let StationViewInnerLabelTop_Width_Space:CGFloat = 12

@objc protocol StationViewDelegate{
    func addStationButtonTap(_ sender:UIButton)
    func stationViewTapAction(_ sender:MyStationTapGestureRecognizer)
}

class MyStationView: UIView {
    var stationArray:Array<StationModel>?
    weak var delegate: StationViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.addSubview(myStationLabel)
        getDataSource()
        setStationsView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func stationViewTap(_ gesture:MyStationTapGestureRecognizer){
        if let delegateOK = self.delegate{
            delegateOK.stationViewTapAction(gesture)
        }
    }
    
    
    @objc func addButtonClick(_ sender:UIButton) {
        if let delegateOK = self.delegate{
            delegateOK.addStationButtonTap(sender)
        }
    }
    
    @objc func detailButtonClick(_ sender:UIButton){
       
    }
    
    func getDataSource() {
        
        let stationModel1 = StationModel.init()
        stationModel1.type = "normal"
        stationModel1.name = "WISNUC Station1"
        
        let stationModel2 = StationModel.init()
        stationModel2.type = "local"
        stationModel2.name = "WISNUC Station2"
        
        let stationModel3 = StationModel.init()
        stationModel3.type = "offline"
        stationModel3.name = "自定义设备"
        
        let stationModel4 = StationModel.init()
        stationModel4.type = "checking"
        stationModel4.name = "设备666"
        stationArray = []
        stationArray?.append(stationModel1)
        stationArray?.append(stationModel2)
        stationArray?.append(stationModel3)
        stationArray?.append(stationModel4)
    }
    
    func setStationsView() {
        let page = (stationArray?.count)!/2 + 1
        stationScrollView.contentSize = CGSize(width: self.width, height: CGFloat(page*Int(ViewHeight + Width_Space)))
        self.addSubview(stationScrollView)
        setDetailStationsView()
        setAddButtonView()
    }
    
    func setDetailStationsView(){
        var index:Int = 0
        var page:Int = 0
        for (idx,value) in (stationArray?.enumerated())! {
            index = idx % 2
            page = idx/2
            Start_Y = myStationLabel.frame.maxY + MarginsWidth
            let view = UIView.init(frame: CGRect(x: CGFloat(index) * (ViewWidth + Width_Space) + Start_X, y: CGFloat(page) * (ViewHeight + Height_Space) + Start_Y, width: ViewWidth, height: ViewHeight))
            view.backgroundColor = UIColor.clear
            view.tag = idx
            view.isUserInteractionEnabled = true
            
            let model:StationModel = value
            let tapGesture = MyStationTapGestureRecognizer.init(target: self, action: #selector(stationViewTap(_ :)))
            tapGesture.stationButtonType = model.type.map { StationButtonType(rawValue: $0) }!
            tapGesture.stationName = model.name
            view.addGestureRecognizer(tapGesture)
            
            let button = detailButton(buttonType:StationButtonType(rawValue: model.type!)!)
            view.addSubview(detailIconView(type: StationButtonType(rawValue: model.type!)!, center: CGPoint(x:button.right , y: button.top)))
            view.addSubview(button)
            let functionLabel = functionOrStationNameLabel(text: model.name!, top: button.frame.maxY + StationViewInnerLabelTop_Width_Space)
            view.addSubview(functionLabel)
            
            let describeLabel = functionOrStationNameLabel(text: describeString(type: StationButtonType(rawValue: model.type!)!), top: functionLabel.bottom + MarginsCloseWidth)
            describeLabel.font = SmallTitleFont
            describeLabel.textColor = LightGrayColor
            view.addSubview(describeLabel)
            stationScrollView.addSubview(view)
        }
    }
    
    func setAddButtonView() {
        let addButtonIndex = (stationArray?.count)! % 2
        let addButtonPage = (stationArray?.count)! / 2
        let view = UIView.init(frame: CGRect(x: CGFloat(addButtonIndex) * (ViewWidth + Width_Space) + Start_X, y: CGFloat(addButtonPage) * (ViewHeight + Height_Space) + Start_Y, width: ViewWidth, height: ViewHeight))
        let addButton = detailButton(buttonType: .addNew)
        view.addSubview(addButton)
        view.addSubview(functionOrStationNameLabel(text: LocalizedString(forKey: "add_Device"), top: addButton.frame.maxY + StationViewInnerLabelTop_Width_Space))
        stationScrollView.addSubview(view)
    }
    
    func functionOrStationNameLabel(text:String,top:CGFloat) -> UILabel {
        let labelText = text
        let labelFont = MiddleTitleFont
        let labelWidth = labelWidthFrom(title: labelText, font: labelFont)
        let labelHeight = labelHeightFrom(title: labelText, font: labelFont)
        let label = UILabel.init(frame: CGRect(x: (ViewWidth - labelWidth)/2, y: top, width:labelWidth , height: labelHeight))
        label.font = labelFont
        label.text = labelText
        label.textAlignment = NSTextAlignment.center
        return label
    }
    
    func detailButton(buttonType:StationButtonType) -> UIButton {
        let buttonIndex = (stationArray?.count)! % 2
        let buttonPage = (stationArray?.count)! / 2
        
        let view = UIView.init(frame: CGRect(x: CGFloat(buttonIndex) * (ViewWidth + Width_Space) + Start_X, y: CGFloat(buttonPage) * (ViewHeight + Height_Space) + Start_Y, width: ViewWidth, height: ViewHeight))
    
        let button = UIButton.init()
        var buttonImageName:String?
        switch buttonType {
        case .addNew:
            buttonImageName = "add_station"
            button.addTarget(self, action: #selector(addButtonClick(_ :)), for: UIControlEvents.touchUpInside)
        default:
            buttonImageName = "device"
            button.isUserInteractionEnabled = false
//            button.addTarget(self, action: #selector(detailButtonClick(_ :)), for: UIControlEvents.touchUpInside)
           break
        }
        
        let buttonImage = UIImage.init(named: buttonImageName!)
        button.frame = CGRect(x: (view.width - (buttonImage?.size.width)!)/2  , y: StationViewInnerImageViewTop_Width_Space, width: ButtonWidth, height: ButtonHeight)
        button.setImage(buttonImage, for: UIControlState.normal)
        return button
    }
    
    func describeString(type:StationButtonType) ->String {
        switch type {
        case .normal:
            return ""
        case .checking:
            return LocalizedString(forKey: "station_checking")
        case .diskError:
            return LocalizedString(forKey: "station_disk_error")
        case .offline:
            return LocalizedString(forKey: "station_offline")
        case .local:
            return LocalizedString(forKey: "station_local")
        default:
            return ""
        }
    }
    
    func detailIconView(type:StationButtonType,center:CGPoint) -> UIImageView {
        let imageView = UIImageView.init(frame: CGRect(x: 0, y:0 , width: IconWidth, height: IconHeight))
        imageView.center = center
        var imageName:String!
        switch type {
        case .normal:
            imageName =  "station_normal.png"
        case .checking:
            imageName =  "station_review.png"
        case .diskError:
            imageName =  "disk_warning.png"
        case .offline:
            imageName =  "offline.png"
        case .local:
            imageName =  "local_area.png"
        default:
            break
        }
        imageView.image = UIImage.init(named: imageName)
        return imageView
    }
    
    lazy var myStationLabel: UILabel = {
        let string = LocalizedString(forKey: "my_station")
        let font = SmallTitleFont
        let lable = UILabel.init(frame: CGRect(x:MarginsWidth , y:20 , width: labelWidthFrom(title: string, font: font), height: labelHeightFrom(title: string, font: font)))
        lable.font = font
        lable.text = string
        lable.textColor = LightGrayColor
        return lable
    }()
    
//    lazy var myStationLabelView: UIView = {
//        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: __kWidth))
//        return <#value#>
//    }()
    
    lazy var stationScrollView: UIScrollView = {
        let scrollView = UIScrollView.init(frame: CGRect(x: 0, y:myStationLabel.bottom + MarginsWidth , width: __kWidth, height: self.height - myStationLabel.bottom - MarginsWidth))
        scrollView.isScrollEnabled = true
        return scrollView
    }()
}
