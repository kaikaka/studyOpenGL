//
//  ViewController.swift
//  OpenGLESImage
//
//  Created by KaiKing on 2021/7/14.
//

import GLKit
import OpenGLES
import UIKit


class ViewController: UIViewController {
 
    var displayLink:CADisplayLink!
    var angle:Double = 0
    var colorViewArrays:[UIView] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        self.createFace()
        self.addFaces()
        self.addCADisplayLink()
    }
    
    func createFace() {
        let colors = [UIColor.red,UIColor.orange,UIColor.brown,UIColor.purple,UIColor.gray,UIColor.green]
        for (idx,item) in colors.enumerated() {
            let view = UIView.init(frame: CGRect.init(x: 100, y: idx * 200 + 20, width: 200, height: 200))
            view.backgroundColor = item
            
            let label = UILabel.init(frame: CGRect.init(x: 80, y: 80, width: 40, height: 40))
            label.textColor = UIColor.white
            label.text = "\(idx)"
            label.textAlignment = .center
            view.addSubview(label)
            self.colorViewArrays.append(view)
        }
    }
    
    func addFaces() {
        //让整个view左右偏移90度
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 500
        //绕x轴向下旋转45度
        perspective = CATransform3DRotate(perspective, CGFloat(-Double.pi/4), 1, 0, 0)
        perspective = CATransform3DRotate(perspective, CGFloat(-Double.pi/4), 0, 1, 0)
        perspective = CATransform3DRotate(perspective, CGFloat(-Double.pi/8), 0, 0, 1)
        self.view.layer.sublayerTransform = perspective
        
        //z轴 距离中心点正100
        var transform = CATransform3DMakeTranslation(0, 0, 100)
        self.addFace(idx: 0, transform: transform)
        
        transform = CATransform3DMakeTranslation(100, 0, 0)
        transform = CATransform3DRotate(transform, CGFloat(Double.pi / 2.0), 0, 1, 0)
        self.addFace(idx: 1, transform: transform)
        
        transform = CATransform3DMakeTranslation(0, -100, 0)
        transform = CATransform3DRotate(transform, CGFloat(Double.pi / 2.0), 1, 0, 0)
        self.addFace(idx: 2, transform: transform)
        
        transform = CATransform3DMakeTranslation(0, 100, 0);
        transform = CATransform3DRotate(transform, CGFloat(-Double.pi / 2.0), 1, 0, 0);
        self.addFace(idx: 3, transform: transform)
        
        transform = CATransform3DMakeTranslation(-100, 0, 0);
        transform = CATransform3DRotate(transform, CGFloat(-Double.pi / 2.0), 0, 1, 0);
        self.addFace(idx: 4, transform: transform)
        
        transform = CATransform3DMakeTranslation(0, 0, -100);
        transform = CATransform3DRotate(transform, CGFloat(Double.pi), 0, 1, 0);
        self.addFace(idx: 5, transform: transform)
        
        //以上操作可以让平面拼合成一个正方体
    }
    
    func addFace(idx:Int,transform:CATransform3D) {
        let face = self.colorViewArrays[idx]
        self.view.addSubview(face)
        
        let contaninerSize = self.view.bounds.size
        face.center = CGPoint.init(x: contaninerSize.width / 2.0, y: contaninerSize.height / 2.0)
        face.layer.transform = transform
    }
    func addCADisplayLink() {
        self.displayLink = CADisplayLink.init(target: self, selector: #selector(onActionLink))
        self.displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    @objc func onActionLink() {
        self.angle = (self.angle + 3).truncatingRemainder(dividingBy: 360)
        let deg = self.angle * (Double.pi / 180)
        var temp = CATransform3DIdentity
        //实际上旋转的是父视图 而不是立方体，0.5，1，0.7 是围绕旋转的轴
        temp = CATransform3DRotate(temp, CGFloat(deg), 0.5, 1, 0.7)
        self.view.layer.sublayerTransform = temp
    }
}
