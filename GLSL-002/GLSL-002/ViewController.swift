//
//  ViewController.swift
//  GLSL-001
//
//  Created by KaiKing on 2021/9/6.
//

import UIKit

class ViewController: UIViewController {
    var glview:GLView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        glview = self.view as! GLView
        let gview = GLView.init(frame: CGRect.init(x: 0, y: 100, width: 524, height: 486))
        self.view.addSubview(gview)
    }


}

