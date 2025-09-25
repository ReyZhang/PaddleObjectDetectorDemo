//
//  ViewController.swift
//  PaddleDemo
//
//  Created by boss on 2025/7/7.
//

import UIKit


class ViewController: UIViewController {
    
    
    lazy var detectBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("目标检测", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.backgroundColor = UIColor.blue
        
        return btn
    }()
    
    
    lazy var loadBtn : UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("从服务器更新模型", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.backgroundColor = UIColor.blue
        
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.detectBtn)
        self.detectBtn.frame = CGRectMake(50, 200, CGRectGetWidth(self.view.frame) - 50 * 2, 50)
        self.detectBtn.addTarget(self, action: #selector(detectObject), for: .touchUpInside)

        
        self.view.addSubview(self.loadBtn)
        self.loadBtn.frame = CGRectMake(50, 300, CGRectGetWidth(self.view.frame) - 50 * 2, 50)
        self.loadBtn.addTarget(self, action: #selector(loadModel), for: .touchUpInside)
    }

    
    @objc func detectObject() {

        
        let image = UIImage(named: "1000")
        let objectDetector = ObjectDetectorNative()
        objectDetector.detectSwift(options: ["imagePath":image]) { result in
            print("识别结果：\(result)")
        }
        
    }
    
    
    @objc func loadModel() {
        print("当前模型版本：\(ResourceManager.localVersion())")
        
        
        //模型检查与更新
        let manager = ResourceManager()
        let serverVersion = "1.0.0"
        let resourceUrl = "http://sz001.shangtuoguan.cn/version.zip"
        if let url = URL(string: resourceUrl) {
            manager.checkAndUpdateModel(fromVersion: serverVersion, resourceUrl: url) { success, message in
                print("输出信息：\(message)")
            }
           
        }
        
        
    }
    

}

