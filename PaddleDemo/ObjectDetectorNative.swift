//
//  ObjectDetectorNative.swift
//  PaddleDemo
//
//  Created by boss on 2025/7/7.
//

import Foundation
import PaddleObjectDetector

public typealias ValueChanged = ([String:Any]) -> Void

@objc public class ObjectDetectorNative : NSObject, ObjectDetectorDelegate {
    
    
    var resultBlock: ValueChanged?
    var inputImage: UIImage?
    var resultJson = [String: Any]()
    var input_threshold = 0.5
    
    // MARK: - UNI_EXPORT_METHOD(detect:callback:)
    /// 目标检测
    /// - Parameters:
    ///   - options: 包含 "image" 键，值为 UIImage 或 本地路径 String
    ///   - callback: 结果回调
    public func detectSwift(options: [String: Any]?, callback: @escaping ValueChanged) {
        resultJson.removeAll()
        resultBlock = callback
        
        // 参数校验
        guard let opts = options, !opts.isEmpty else {
            constructErrorJson("参数未传递")
            resultBlock?(resultJson)
            return
        }
        
        // 处理 image 参数
        if let img = opts["imagePath"] as? UIImage {
            inputImage = img
        } else if let path = opts["imagePath"] as? String {
            convertToImages(path)
        }
        
        guard inputImage != nil else {
            constructErrorJson("image 参数无效或文件不存在")
            resultBlock?(resultJson)
            return
        }
        
        if let threshold = opts["threshold"] as? Double {
            input_threshold = threshold
        }
        
        
        beginDetect()
    }
    
    // MARK: - 构造错误/成功 JSON
    private func constructErrorJson(_ message: String) {
        resultJson.removeAll()
        resultJson["code"] = "error"
        resultJson["message"] = message
    }
    
    private func constructSuccessJson(_ dataArray: [[String: Any]]) {
        resultJson.removeAll()
        resultJson["code"] = "success"
        resultJson["data"] = dataArray
    }
    
    // MARK: - 路径转 UIImage
    private func convertToImages(_ imagePath: String) {
        var p = imagePath
        if p.hasPrefix("file://") {
            p = String(p.dropFirst("file://".count))
        }
        inputImage = UIImage(contentsOfFile: p)
    }
    
    // MARK: - 开始检测
    private func beginDetect() {
        // 加载资源 bundle
        let bundle = Bundle(for: type(of: self))
        
        //先判断Documents目录下是否有指定资源， 如果没有则Copy到documents目录下
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let modelPath = docPath.appendingPathComponent("picodet_l_640_cpu.nb").path
        let labelsPath = docPath.appendingPathComponent("ti_label_list.txt").path
        
        if !FileManager.default.fileExists(atPath: modelPath) {
            try? FileManager.default.copyItem(atPath: bundle.path(forResource: "picodet_l_640_cpu", ofType: "nb") ?? "", toPath: modelPath)
        }
        
        if !FileManager.default.fileExists(atPath: labelsPath) {
            try? FileManager.default.copyItem(atPath: bundle.path(forResource: "ti_label_list", ofType: "txt") ?? "", toPath: labelsPath)
        }
        
        // 配置模型信息
        let modelInfo = ObjectDetectorModelInfo()
        modelInfo.modelType = .picodet
        modelInfo.modelPath = modelPath
        modelInfo.labelsPath = labelsPath
        modelInfo.threshold = input_threshold
        
        // 创建检测器
        let detector = ObjectDetector(model: modelInfo, delegate: self)
        detector.detect(inputImage!)
    }
    
    // MARK: - ObjectDetectorDelegate
    public func objectDetector(_ detector: ObjectDetector,
                               result array: [DetectedObjectInfo],
                               useTime time: DetectedTimeInfo) {
        var objArray = [[String: Any]]()
        
        for info in array {
            var dic = [String: Any]()
            dic["label"]       = info.class_name
            dic["confidence"]  = info.score
            dic["x"]           = info.rect.origin.x
            dic["y"]           = info.rect.origin.y
            dic["width"]       = info.rect.size.width
            dic["height"]      = info.rect.size.height
            objArray.append(dic)
        }
        
        constructSuccessJson(objArray)
        resultBlock?(resultJson)
    }
    
    
}

