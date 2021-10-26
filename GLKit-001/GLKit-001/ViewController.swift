//
//  ViewController.swift
//  GLKit-001
//
//  Created by KaiKing on 2021/10/25.
//

import UIKit
import GLKit

class ViewController: GLKViewController,GLKViewControllerDelegate {

    var xDegree: Float = 0
    var yDegree: Float = 0
    var zDegree: Float = 0
    
    var bX:Bool = false
    var bY:Bool = false
    var bZ:Bool = false
    
    lazy var mContext = EAGLContext.init(api: .openGLES2)
    var count:Int = 0
    
    lazy var mEffect:GLKBaseEffect = GLKBaseEffect()
    
    lazy var timer:DispatchSourceTimer = DispatchSource.makeTimerSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.view.backgroundColor = UIColor.black
        
        self.setupContext()
        self.render()
    }
    @IBAction func X(_ sender: Any) {
        bX = !bX
    }
    
    @IBAction func Y(_ sender: Any) {
        bY = !bY
    }
    
    @IBAction func Z(_ sender: Any) {
        bZ = !bZ
    }
    /// Mark GLKViewControllerDelegate
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        var modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.5)
        modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, xDegree)
        modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, yDegree)
        modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, zDegree)
        mEffect.transform.modelviewMatrix = modelViewMatrix
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.3, 0.4, 0.4, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        mEffect.prepareToDraw()
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(self.count), GLenum(GL_UNSIGNED_INT), UnsafeMutablePointer(bitPattern: 0))
    }
    
    func setupContext() {
        let view:GLKView = self.view as! GLKView
        view.context = self.mContext!
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .format24
        EAGLContext.setCurrent(self.mContext)
        glEnable(GLenum(GL_DEPTH_TEST))
    }
    
    func render() {
        let attrArr: [GLfloat] = [
            -0.5, 0.5, 0.0,      1.0, 0.0, 1.0, //左上
            0.5, 0.5, 0.0,       1.0, 0.0, 1.0, //右上
            -0.5, -0.5, 0.0,     1.0, 1.0, 1.0, //左下
            
            0.5, -0.5, 0.0,      1.0, 1.0, 1.0, //右下
            0.0, 0.0, 1.0,       0.0, 1.0, 0.0, //顶点
        ]
        
        let indices: [GLuint] = [
                    0, 3, 2,
                   0, 1, 3,
                   0, 2, 4,
                   0, 4, 1,
                   2, 3, 4,
                   1, 4, 3,
        ]
        self.count = MemoryLayout<GLuint>.size * indices.count / MemoryLayout<GLuint>.size
        
        //开辟顶点缓存区
        var buffer: GLuint = GLuint()
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * attrArr.count, attrArr, GLenum(GL_STATIC_DRAW))
        //开辟索引缓存区
        var indext:GLuint = GLuint()
        glGenBuffers(1, &indext)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indext)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * indices.count, indices, GLenum(GL_STATIC_DRAW))
        
        //使用顶点
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 6), UnsafeMutablePointer(bitPattern: 0))
        //使用索引
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.color.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.color.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 6), UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        //着色器
        let size = self.view.bounds.size
        let aspect = fabs(size.width / size.height)
        var projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), Float(aspect), 0.1, 100.0)
        projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0, 1, 1)
        mEffect.transform.projectionMatrix = projectionMatrix
        
        //模型视图矩阵
        var modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.0)
        mEffect.transform.modelviewMatrix = modelViewMatrix
        
        let seconds:Double = 0.1
        timer.schedule(deadline: DispatchTime.now(), repeating: seconds, leeway: .microseconds(10))
        timer.setEventHandler {
            self.xDegree += 0.1 * (self.bX ? 1 : 0)
            self.yDegree += 0.1 * (self.bY ? 1 : 0)
            self.zDegree += 0.1 * (self.bZ ? 1 : 0)
        }
        timer.resume()
    }
}

