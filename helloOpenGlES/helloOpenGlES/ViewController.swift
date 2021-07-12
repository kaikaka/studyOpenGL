//
//  ViewController.swift
//  HelloOpenGlES
//
//  Created by KaiKing on 2021/7/12.
//

import UIKit
import GLKit
import OpenGLES

class ViewController: GLKViewController {

    var context:EAGLContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //1.初始化
        //2.获取glkview &设置context
        //3.设置背景颜色
        context = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        if context == nil {
            print("failed")
        }
        
        EAGLContext.setCurrent(context)
        guard let gView = self.view as? GLKView else {
            return
        }
        gView.context = context!
        glClearColor(1, 0, 0, 1.0)
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
}

