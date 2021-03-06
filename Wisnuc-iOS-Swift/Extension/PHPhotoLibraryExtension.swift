//
//  PHPhotoLibraryExtension.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/7/6.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import Foundation
import Photos
extension PHPhotoLibrary{
    class func getAllVideoAssets() ->Array<PHAsset>{
        let options = PHFetchOptions.init()
        options.includeHiddenAssets = true
        var tempDic = Dictionary<String, PHAsset>.init()
        let assetResult: PHFetchResult? = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: options)
        autoreleasepool {
            assetResult?.enumerateObjects({ (obj, idx, stop) in
                tempDic[obj.localIdentifier] = obj
            })
        }
        return tempDic.map({$0.value})
//        re
//        var options2 = PHVideoRequestOptions()
//        options2.deliveryMode = .automatic
//        for a: PHAsset? in assetsResult! {
//            if let anA = a {
//                PHImageManager.default().requestAVAsset(forVideo: anA, options: options2, resultHandler: { asset, audioMix, info in
//                    if let anInfo = info {
//                        print("\(anInfo)")
//                    }
//                })
//            }
//        }
    }
    
    class func getCameraRollAlbumList(allowSelectVideo:Bool,allowSelectImage:Bool) -> WSAssetList?{
        let option = PHFetchOptions.init()
        if !allowSelectVideo{
            option.predicate = NSPredicate.init(format:"mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        if !allowSelectImage{
            option.predicate = NSPredicate.init(format:"mediaType == %ld", PHAssetMediaType.video.rawValue);
        }
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        var m:WSAssetList?
        smartAlbums.enumerateObjects { (collection, idx, stop) in
            //获取相册内asset result
            let result = PHAsset.fetchAssets(in: collection, options: option)
            if collection.assetCollectionSubtype.rawValue == 209 {
                m = PHPhotoLibrary.getAlbumMode(title: collection.localizedTitle, result: result, allowSelectVideo: allowSelectVideo, allowSelectImage: allowSelectImage)
                m?.isCameraRoll = true
            }
        }
        return m
    }
    
    class func getCameraRollAlbumList(allowSelectVideo:Bool,allowSelectImage:Bool,sortAscending:Bool) -> WSAssetList?{
        let option = PHFetchOptions.init()
        if !allowSelectVideo{
            option.predicate = NSPredicate.init(format:"mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        if !allowSelectImage{
            option.predicate = NSPredicate.init(format:"mediaType == %ld", PHAssetMediaType.video.rawValue);
        }
        
        if !sortAscending{
            option.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: sortAscending)]
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        var m:WSAssetList?
        smartAlbums.enumerateObjects { (collection, idx, stop) in
            //获取相册内asset result
            let result = PHAsset.fetchAssets(in: collection, options: option)
            if collection.assetCollectionSubtype.rawValue == 209 {
                m = PHPhotoLibrary.getAlbumMode(title: collection.localizedTitle, result: result, allowSelectVideo: allowSelectVideo, allowSelectImage: allowSelectImage)
                m?.isCameraRoll = true
            }
        }
        return m
    }
    
    class func getAlbumMode(title:String?,result:PHFetchResult<PHAsset>?,allowSelectVideo:Bool,allowSelectImage:Bool)->WSAssetList{
        let model = WSAssetList.init()
        model.title = title
        model.count = result?.count
        model.result = result
        //为了获取所有asset gif设置为yes
        model.models = PHPhotoLibrary.getPhotoInResult(result: result, allowSelectVideo: allowSelectVideo, allowSelectImage: allowSelectImage, allowSelectGif: allowSelectImage, allowSelectLivePhoto: allowSelectImage)
        return model;
    }
    
    // MARK: - 根据照片数组对象获取对应photomodel数组
    class func getPhotoInResult(result:PHFetchResult<PHAsset>?,allowSelectVideo:Bool,allowSelectImage:Bool,allowSelectGif:Bool,allowSelectLivePhoto:Bool) ->Array<WSAsset> {
        return PHPhotoLibrary.getPhotoInResult(result: result, allowSelectVideo: allowSelectVideo, allowSelectImage: allowSelectImage, allowSelectGif: allowSelectGif, allowSelectLivePhoto: allowSelectLivePhoto, limitCount: Int(INT_MAX))
        }
    
    class func getPhotoInResult(result:PHFetchResult<PHAsset>?,allowSelectVideo:Bool,allowSelectImage:Bool,allowSelectGif:Bool,allowSelectLivePhoto:Bool,limitCount:Int) ->Array<WSAsset>{
        var arrModel:Array<WSAsset> = Array.init()
        var count:Int = 1
        result?.enumerateObjects { (obj, idx, stop) in
            let type:WSAssetType = obj.getWSAssetType()
            if (type == .Image && !allowSelectImage) {return}
            if (type == .GIF && !allowSelectImage) {return}
            if (type == .LivePhoto && !allowSelectImage) {return}
            if (type == .Video && !allowSelectVideo) {return}
            
            if (count == limitCount) {
                stop.pointee = true
            }
            
            let duration = obj.getDurationString()
            arrModel.append( WSAsset.assetModel(asset: obj, type: type, duration: duration))
            count = +1
        }
        
        return arrModel;
    }
    
    class func requestSelectedImage(model:WSAsset,isOriginal:Bool,allowSelectGif:Bool,complete:@escaping ((_ image:UIImage?,_ dictionary:Dictionary<AnyHashable, Any>?)->())) -> PHImageRequestID?{
        if model.type == .GIF && allowSelectGif {
            if model.asset != nil{
            return self.requestOriginalImageData(for: model.asset!, completion: { (data, info) in
                if !(info![PHImageResultIsDegradedKey] as! Bool){
                    let image = PHPhotoLibrary.animatedGIF(with: data!)
                     complete(image!, info as! Dictionary<String, Any>)
                }
            })
            }else{
                return nil
            }
            
        }else{
            if isOriginal {
                return self.requestOriginalImage(for: model.asset!, completion: complete)
            }else{
                let scale:CGFloat = 2
                let width:CGFloat = min(__kWidth, __kHeight)
                let size = CGSize(width: width*scale, height: width * scale * CGFloat((model.asset?.pixelHeight)!/(model.asset?.pixelWidth)!))
    
                return self.requestImage(for: model.asset!, size: size, completion:complete)
            }
        }
    }
    
    
    
    class func getAllAsset(complete:@escaping (_ result:PHFetchResult<PHAsset>,_ assets:Array<PHAsset>)->()){
        var tempDic = Dictionary<String, PHAsset>.init()
        let collectionResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary, options: nil)
        let options = PHFetchOptions.init()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        collectionResult.enumerateObjects { (c, idx, stop) in
            //            if c.assetCollectionSubtype == 100){continue} //屏蔽 我的照片流
            
            // 遍历这个相册中的所有图片
            let assetResult = PHAsset.fetchAssets(in: c, options: options)
            autoreleasepool {
            assetResult.enumerateObjects({ (obj, idx, stop) in
                tempDic[obj.localIdentifier] = obj
            })
            }
          
        }
        options.includeHiddenAssets = true
        let lastresult = PHAsset.fetchAssets(with: options)
         autoreleasepool {
        lastresult.enumerateObjects({ (obj, idx, stop) in
            tempDic[obj.localIdentifier] = obj
        })
        }
        complete(lastresult,tempDic.map({$0.value}))
    }
}

