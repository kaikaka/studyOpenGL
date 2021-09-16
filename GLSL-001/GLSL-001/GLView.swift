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
    var myPrograme: GLuint = GLuint()

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
        self.renderLayer()
    }

    // 设置图层
    func setupLayer() {
        if let layer = self.layer as? CAEAGLLayer {
            eagLayer = layer
            contentScaleFactor = UIScreen.main.scale
            eagLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]
        }
    }

    func setupContect() {
        let api = EAGLRenderingAPI.openGLES3
        guard let context = EAGLContext(api: api) else { return }
        EAGLContext.setCurrent(context)
        myContext = context
    }

    func deleteRenderAndFrameBuffer() {
        glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
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
        glClearColor(0.3, 0.45, 0.6, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let scale = UIScreen.main.scale
        glViewport(GLint(frame.origin.x * scale), GLint(frame.origin.y * scale), GLsizei(frame.size.width * scale), GLsizei(frame.size.height * scale))
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "vsh")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "fsh")
        myPrograme = loadShaders(vertFile ?? "", frag: fragFile ?? "")
        glLinkProgram(myPrograme)
        var linkStatus: GLint = GLint()
        glGetProgramiv(myPrograme, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GLint(GL_FALSE) {
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(myPrograme, GLsizei(MemoryLayout<GLchar>.stride * 512), nil, message)
            let messageString = String(utf8String: message)
            print("program link error \(messageString)")
            return
        }
        glUseProgram(myPrograme)
        let attrArr: [GLfloat] = [
            0.5, -0.5, -1.0, 1.0, 0.0,
            -0.5, 0.5, -1.0, 0.0, 1.0,
            -0.5, -0.5, -1.0, 0.0, 0.0,

            0.5, 0.5, -1.0, 1.0, 1.0,
            -0.5, 0.5, -1.0, 0.0, 1.0,
            0.5, -0.5, -1.0, 1.0, 0.0,
        ]
        var attrBuffer: GLuint = GLuint()
        glGenBuffers(1, &attrBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * attrArr.count, attrArr, GLenum(GL_DYNAMIC_DRAW))
        let position = glGetAttribLocation(myPrograme, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size) * 5, UnsafeRawPointer(bitPattern: 0))

        let textColor = glGetAttribLocation(myPrograme, "textCoordinate")
        glEnableVertexAttribArray(GLuint(textColor))
        glVertexAttribPointer(GLuint(textColor), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size) * 5, UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        setupTexture("dog")
        glUniform1i(glGetUniformLocation(myPrograme, "colorMap"), 0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }

    func loadShaders(_ vert: String, frag: String) -> GLuint {
        let program:GLuint = glCreateProgram()
        guard let verShader = compileShader(GLenum(GL_VERTEX_SHADER), file: vert) else { return 0 }
        guard let fragShader = compileShader(GLenum(GL_FRAGMENT_SHADER), file: frag) else { return 0 }
        glAttachShader(program, verShader)
        glAttachShader(program, fragShader)
        glDeleteShader(verShader)
        glDeleteShader(fragShader)
        return program
    }

    func compileShader(_ type: GLenum, file: String) -> GLuint? {
        let content = try! String(contentsOfFile: file, encoding: String.Encoding.utf8)
        print(content)
        let shader:GLuint = glCreateShader(type)
        content.withCString({ pointer in
            var p: UnsafePointer<GLchar>? = pointer
            glShaderSource(shader, 1, &p, nil)
        })
        glCompileShader(shader)
        return shader
    }

    func setupTexture(_ fileName: String) {
        guard let spriteImage = UIImage(named: fileName)?.cgImage else { return }
        let spriteData: UnsafeMutablePointer<GLubyte> = UnsafeMutablePointer<GLubyte>.allocate(capacity: spriteImage.width * spriteImage.height * 4 * MemoryLayout<GLubyte>.size)

        UIGraphicsBeginImageContext(CGSize(width: spriteImage.width, height: spriteImage.height))

        var spriteContext = CGContext(data: spriteData, width: spriteImage.width, height: spriteImage.height, bitsPerComponent: 8, bytesPerRow: spriteImage.width * 4, space: spriteImage.colorSpace!, bitmapInfo: spriteImage.bitmapInfo.rawValue)
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: spriteImage.width, height: spriteImage.height))
        UIGraphicsEndImageContext()
        spriteContext = nil
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(spriteImage.width), GLsizei(spriteImage.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        free(spriteData)
    }

    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
}
