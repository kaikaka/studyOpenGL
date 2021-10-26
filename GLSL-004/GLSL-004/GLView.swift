//
//  GLView.swift
//  GLSL-001
//
//  Created by KaiKing on 2021/9/6.
//

import OpenGLES
import UIKit

class GLView: UIView {
    var eagLayer: CAEAGLLayer?
    var myContext: EAGLContext?
    var myColorRenderBuffer: GLuint = GLuint()
    var myColorFrameBuffer: GLuint = GLuint()
    var myProgram: GLuint = GLuint()
    var myVertices: GLuint = GLuint()

    
    var xDegree: Float = 0
    var yDegree: Float = 0
    var zDegree: Float = 0
    
    override func layoutSubviews() {
        // 1.设置图层
        setupLayer()
        // 2.设置图形上下文
        setupContect()
        // 3.清空缓存区
        deleteRenderAndFrameBuffer()
        // 4.设置renderbuffer
        setupRenderBuffer()
        // 5.设置framebuffer
        setupFrameBuffer()
        // 6.绘制
        renderLayer()
    }

    // 初始化图层
    func setupLayer() {
        if let layer = self.layer as? CAEAGLLayer {
            eagLayer = layer
            contentScaleFactor = UIScreen.main.scale
            eagLayer?.isOpaque = true
            eagLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]
        }
    }

    func setupContect() {
        guard let context = EAGLContext(api: EAGLRenderingAPI.openGLES2) else { return }
        EAGLContext.setCurrent(context)
        myContext = context
    }

    func deleteRenderAndFrameBuffer() {
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
        glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
    }

    func setupRenderBuffer() {
        glGenRenderbuffers(1, &myColorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        myContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: eagLayer)
    }

    func setupFrameBuffer() {
        glGenBuffers(1, &myColorFrameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }

    func renderLayer() {
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let scale = UIScreen.main.scale
        glViewport(GLint(frame.origin.x * scale), GLint(frame.origin.y * scale), GLsizei(frame.size.width * scale), GLsizei(frame.size.height * scale))
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "glsl")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "glsl")
        myProgram = loadShaders(vertFile ?? "", frag: fragFile ?? "")
        
        guard myProgram != 0 else{
            return
        }
        let attrArr: [GLfloat] = [
            -0.5, 0.5, 0.0,      1.0, 1.0, 1.0, //左上0
            0.5, 0.5, 0.0,       1.0, 1.0, 1.0, //右上1
            -0.5, -0.5, 0.0,     1.0, 1.0, 1.0, //左下2

            0.5, -0.5, 0.0,      1.0, 1.0, 1.0, //右下3
            0.0, 0.0, 1.0,       1.0, 1.0, 0.0, //顶点4
        ]
        
        let indices:[GLuint] = [
            0,3,2,
            0,1,3,
            0,2,4,
            0,4,1,
            2,3,4,
            1,4,3,
        ]
        if  myVertices == 0 {
            glGenBuffers(1, &myVertices)
        }
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), myVertices)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * attrArr.count, attrArr, GLenum(GL_DYNAMIC_DRAW))
        
        let position = glGetAttribLocation(myProgram, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 6), UnsafeMutablePointer(bitPattern: 0))
        
        let positionColor = glGetAttribLocation(myProgram, "positionColor")
        glEnableVertexAttribArray(GLuint(positionColor))
        glVertexAttribPointer(GLuint(positionColor), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size) * 6, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        
        //纹理
        let textCoord = glGetAttribLocation(myProgram, "textCoordinate")
        glEnableVertexAttribArray(GLuint(textCoord))
        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*8, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size*6))
        
        setupTexture("dog")
        glUniform1i(glGetUniformLocation(myProgram, "colorMap"), 0)
        
        
        let projectionMatrixSlot = glGetUniformLocation(myProgram, "projrctionMatrix")
        let modelViewMatrixSlot = glGetUniformLocation(myProgram, "modelViewMatrix")
        
        let width:Float = Float(self.frame.size.width)
        let height:Float = Float(self.frame.size.height)
        
        //取得一个单元矩阵
        var projectionMatrix:KSMatrix4 = KSMatrix4()
        ksMatrixLoadIdentity(&projectionMatrix)
        
        let aspect = width / height
        //获得一个新的透视矩阵 30角度变换
        ksPerspective(&projectionMatrix, 30.0, Float(aspect), 5.0, 20.0)
        //https://www.it1352.com/1705628.html 矩阵传递
        var components = MemoryLayout.size(ofValue: projectionMatrix.m) / MemoryLayout.size(ofValue: projectionMatrix.m.0)
        withUnsafePointer(to: &projectionMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components) {
                glUniformMatrix4fv(projectionMatrixSlot, 1, GLboolean(GL_FALSE), $0)
            }
        }
        
        //模型视图矩阵
        var modelViewMatrix: KSMatrix4 = KSMatrix4()
        ksMatrixLoadIdentity(&modelViewMatrix)
        ksTranslate(&modelViewMatrix, 0, 0, -10)
        
        //旋转矩阵
        var rotationMatrix: KSMatrix4 = KSMatrix4()
        ksMatrixLoadIdentity(&rotationMatrix)
        
        ksRotate(&rotationMatrix, xDegree, 1, 0 , 0)
        ksRotate(&rotationMatrix, yDegree, 0, 1, 0)
        ksRotate(&rotationMatrix, zDegree, 0, 0, 1)
        
        //矩阵相乘
        var result :KSMatrix4 = KSMatrix4()
        ksMatrixMultiply(&result, &rotationMatrix, &modelViewMatrix)
        modelViewMatrix = result
        
        //将mv矩阵传递到顶点着色器
        components = MemoryLayout.size(ofValue: modelViewMatrix.m) / MemoryLayout.size(ofValue: modelViewMatrix.m.0)
        withUnsafePointer(to: &modelViewMatrix) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components) {
                glUniformMatrix4fv(modelViewMatrixSlot, 1, GLboolean(GL_FALSE), $0)
            }
        }
        
        glEnable(GLenum(GL_CULL_FACE))
        
        //索引绘图
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(MemoryLayout<GLuint>.size * indices.count / MemoryLayout<GLuint>.size), GLenum(GL_UNSIGNED_INT), indices)
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }

    func loadShaders(_ vert: String, frag: String) -> GLuint {
        var program = glCreateProgram()
        guard let verShader = compileShader(GLenum(GL_VERTEX_SHADER), file: vert) else { return 0 }
        guard let fragShader = compileShader(GLenum(GL_FRAGMENT_SHADER), file: frag) else { return 0 }
        glAttachShader(program, verShader)
        glAttachShader(program, fragShader)
        glDeleteProgram(verShader)
        glDeleteProgram(fragShader)
        
        glLinkProgram(program)
        var linkStatus: GLint = GLint()
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GLint(GL_FALSE) {
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.stride * 512), nil, message)
            let messageString = String(utf8String: message)
            print("program link error \(messageString)")
            return 0
        }
        glUseProgram(program)
        
        return program
    }

    func setupTexture(_ fileName:String) {
        guard let spriteImage = UIImage.init(named: fileName)?.cgImage else { return  }
        let spriteData = UnsafeMutablePointer<GLubyte>.allocate(capacity: MemoryLayout<GLubyte>.size * spriteImage.width * spriteImage.height * 4)
        UIGraphicsBeginImageContext(CGSize.init(width: spriteImage.width, height: spriteImage.height))
        var spriteContext:CGContext = CGContext.init(data: spriteData, width: spriteImage.width, height: spriteImage.height, bitsPerComponent: 8, bytesPerRow: spriteImage.width * 4, space: spriteImage.colorSpace!, bitmapInfo: spriteImage.bitmapInfo.rawValue)!
        let rect = CGRect.init(x: 0, y: 0, width: spriteImage.width, height: spriteImage.height)
        spriteContext.draw(spriteImage, in: rect)
        
        UIGraphicsEndImageContext()
        
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(spriteImage.width), GLsizei(spriteImage.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        free(spriteData)
    }
    
    func compileShader(_ type: GLenum, file: String) -> GLuint? {
        let content = try! String(contentsOfFile: file, encoding: String.Encoding.utf8)
        let shader: GLuint = glCreateShader(type)
        content.withCString { pointer in
            var p: UnsafePointer<GLchar>? = pointer
            glShaderSource(shader, 1, &p, nil)
        }
        glCompileShader(shader)
        return shader
    }

    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
}
