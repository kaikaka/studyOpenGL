//
//  ViewController.swift
//  OpenGLESImage
//
//  Created by KaiKing on 2021/7/14.
//

import GLKit
import OpenGLES
import UIKit

struct GLVertex {
    let postionCoord: GLKVector3!
    let textureCoord: GLKVector2!
    let normal: GLKVector3!
}

class ViewController: UIViewController, GLKViewDelegate {
    var baseEffect: GLKBaseEffect!
    
    lazy var vertices: UnsafeMutablePointer<GLVertex>! = {
        let verticesSize = MemoryLayout<GLVertex>.stride * kCoordCount
        let vertices = UnsafeMutablePointer<GLVertex>.allocate(capacity: verticesSize)
        return vertices
    }()
    
    let kCoordCount: Int = 36
    var vertexBuffer:GLuint = 0
    var displayLink:CADisplayLink!
    var angle:CGFloat = 0
    
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glEnable(GLenum(GL_DEPTH_TEST))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        self.baseEffect.prepareToDraw()
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(kCoordCount))
    }

    var glView: GLKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        self.commonInit()
        self.addCADisplayLink()
    }

    func commonInit() {
        guard let context = EAGLContext(api: EAGLRenderingAPI.openGLES3) else { return }

        EAGLContext.setCurrent(context)

        let frame = CGRect(x: (view.frame.size.width - 500) / 2, y: 100, width: 500, height: 500)
        glView = GLKView(frame: frame, context: context)
        glView.backgroundColor = UIColor.clear
        glView.delegate = self

        // 使用深度缓存
        glView.drawableDepthFormat = GLKViewDrawableDepthFormat.format24
        // 翻转z轴
        glDepthRangef(1, 0)
        // 将glkview 添加到self.view上
        view.addSubview(glView)
        // 获取纹理图片
        guard let path = Bundle.main.path(forResource: "dog", ofType: "jpg") else { return }
        let image = UIImage.init(contentsOfFile: path)
        // 设置纹理参数
        let options = [GLKTextureLoaderOriginBottomLeft: NSNumber(value: true)]
        guard let textureInfo = try? GLKTextureLoader.texture(with: (image?.cgImage)!, options: options) else { return }

        // 使用baseEffect
        baseEffect = GLKBaseEffect()
        baseEffect.texture2d0.name = textureInfo.name
        baseEffect.texture2d0.target = GLKTextureTarget(rawValue: textureInfo.target)!

        // 开启光照效果
        baseEffect.light0.enabled = GLboolean(GL_TRUE)
        // 漫反射颜色
        baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1)
        // 光源位置
        baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1)
        // 开启顶点数据空间
        self.vertices = UnsafeMutablePointer<GLVertex>.allocate(capacity: (MemoryLayout<GLVertex>.size * kCoordCount))
        
        // 前面
        vertices[0] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, 0, 1)))
        vertices[1] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, 0, 1)))
        vertices[2] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (0, 0, 1)))
        vertices[3] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, 0, 1)))
        vertices[4] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (0, 0, 1)))
        vertices[5] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, 0, 1)))
        
        // 上面
        vertices[6] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (0, 1, 0)))
        vertices[7] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, 1, 0)))
        vertices[8] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, 1, 0)))
        vertices[9] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, 1, 0)))
        vertices[10] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, 1, 0)))
        vertices[11] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, 1, 0)))

        // 下面
        vertices[12] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (0, -1, 0)))
        vertices[13] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, -1, 0)))
        vertices[14] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, -1, 0)))
        vertices[15] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, -1, 0)))
        vertices[16] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, -1, 0)))
        vertices[17] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, -1, 0)))

        // 左面
        vertices[18] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (-1, 0, 0)))
        vertices[19] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (-1, 0, 0)))
        vertices[20] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (-1, 0, 0)))
        vertices[21] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (-1, 0, 0)))
        vertices[22] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (-1, 0, 0)))
        vertices[23] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (-1, 0, 0)))

        // 右面
        vertices[24] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, 0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (1, 0, 0)))
        vertices[25] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (1, 0, 0)))
        vertices[26] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (1, 0, 0)))
        vertices[27] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, 0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (1, 0, 0)))
        vertices[28] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (1, 0, 0)))
        vertices[29] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (1, 0, 0)))

        // 后面
        vertices[30] = GLVertex(postionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 1)),
                               normal: GLKVector3(v: (0, 0, -1)))
        vertices[31] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, 0, -1)))
        vertices[32] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, 0, -1)))
        vertices[33] = GLVertex(postionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (0, 0)),
                               normal: GLKVector3(v: (0, 0, -1)))
        vertices[34] = GLVertex(postionCoord: GLKVector3(v: (0.5, 0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 1)),
                               normal: GLKVector3(v: (0, 0, -1)))
        vertices[35] = GLVertex(postionCoord: GLKVector3(v: (0.5, -0.5, -0.5)),
                               textureCoord: GLKVector2(v: (1, 0)),
                               normal: GLKVector3(v: (0, 0, -1)))
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        let bufferSizeBytes = MemoryLayout<GLVertex>.size * kCoordCount
        glBufferData(GLenum(GL_ARRAY_BUFFER), bufferSizeBytes, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint.init(GLKVertexAttrib.position.rawValue))
        let n = MemoryLayout<GLVertex>.stride
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),GLsizei(n),UnsafeMutableRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint.init(GLKVertexAttrib.texCoord0.rawValue))
        
        glVertexAttribPointer(GLuint.init(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(n), UnsafeMutableRawPointer(bitPattern: MemoryLayout<GLKVector3>.stride + 4))
        
        glEnableVertexAttribArray(GLuint.init(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint.init(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),GLsizei(n),UnsafeMutablePointer(bitPattern: MemoryLayout<GLKVector3>.stride + MemoryLayout<GLKVector2>.stride + 8))
    }
    
    func addCADisplayLink() {
        self.displayLink = CADisplayLink.init(target: self, selector: #selector(onActionLink))
        self.displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    @objc func onActionLink() {
        self.angle = (self.angle + 10).truncatingRemainder(dividingBy: 360)
        self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(Float(self.angle)), 0.3, 1, 0.7)
        self.glView.display()
    }
}
