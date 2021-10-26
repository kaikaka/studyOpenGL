//
//  ViewController.swift
//  GLSL-001
//
//  Created by KaiKing on 2021/9/6.
//

import UIKit

class ViewController: UIViewController {
    var glview:GLView!
    var timer: Timer?
    fileprivate var bX: Bool = false;
    fileprivate var bY: Bool = false;
    fileprivate var bZ: Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        glview = (self.view as! GLView)
        glview = GLView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - 100))
        self.view.addSubview(glview)
    }

    @IBAction func Z(_ sender: UIButton) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bZ = !bZ
    }
    @IBAction func X(_ sender: Any) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bX = !bX
    }
    @IBAction func Y(_ sender: UIButton) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bY = !bY
    }
    @objc func reDegree(){
        //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
        //更新度数
        glview.xDegree += (bX ? 1 : 0)*5
        glview.yDegree += (bY ? 1 : 0)*5
        glview.zDegree += (bZ ? 1 : 0)*5
        
        glview.renderLayer()
    }
}

