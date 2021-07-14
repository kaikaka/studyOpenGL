//
//  ViewController.swift
//  OpenGLESImage
//
//  Created by KaiKing on 2021/7/14.
//

import GLKit
import OpenGLES
import UIKit

class ViewController: GLKViewController {
    var context: EAGLContext!
    var cEffect: GLKBaseEffect!

    override func viewDidLoad() {
        super.viewDidLoad()
        // 1.初始化
        // 2.加载顶点/纹理坐标数据
        // 3.加载纹理数据
        setupConfig()
        setupVertexData()
        setupTexture()
    }

    func setupConfig() {
        context = EAGLContext(api: EAGLRenderingAPI.openGLES3)

        if context == nil {
            print("faild")
        }
        EAGLContext.setCurrent(context)
        if let gView = view as? GLKView {
            gView.context = context
            gView.drawableColorFormat = GLKViewDrawableColorFormat.RGBA8888
            gView.drawableDepthFormat = GLKViewDrawableDepthFormat.format16
        }
        glClearColor(1, 1, 0, 1.0)
    }

    func setupVertexData() {
        // 顶点数据
        /*
         纹理坐标系取值范围[0,1];原点是左下角(0,0);
         故而(0,0)是纹理图像的左下角, 点(1,1)是右上角.
         */
        var vertexData: [GLfloat] = [
            0.5, -0.5, 0.0, 1.0, 0.0, // 右下
            0.5, 0.5, 0.0, 1.0, 1.0, // 右上
            -0.5, 0.5, 0.0, 0.0, 1.0, // 左上

            0.5, -0.5, 0.0, 1.0, 0.0, // 右下
            -0.5, 0.5, 0.0, 0.0, 1.0, // 左上
            -0.5, -0.5, 0.0, 0.0, 0.0, // 左下
        ]
        // 开辟顶点缓存区
        var bufferID: GLuint = GLuint() // (1).创建顶点缓存区标识符ID
        glGenBuffers(1, &bufferID)
        // (2).绑定顶点缓存区.(明确作用)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), bufferID)
        // (3).将顶点数组的数据copy到顶点缓存区中(GPU显存中)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * vertexData.count, &vertexData, GLenum(GL_STATIC_DRAW))
        /*
          (1)在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
          意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
          所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
          注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。

         (2)方法简介
         glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)

         功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
         参数列表:
             index,指定要修改的顶点属性的索引值,例如
             size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
             type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
             normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
             stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
             ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
          */
        // 打开读取通道
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue),
                              3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<GLfloat>.stride * 5), nil)

        // 纹理坐标数据
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
    }

    func setupTexture() {
        // 获取纹理路径
        let filePath = Bundle.main.path(forResource: "dog", ofType: "jpg")
        // 旋转坐标 不加这句图片是倒着的
        let options = NSDictionary(object: 1, forKey: GLKTextureLoaderOriginBottomLeft as NSCopying)

        let textureInfo = try! GLKTextureLoader.texture(withContentsOfFile: filePath ?? "", options: options as? [String: NSNumber])
        // 3.使用苹果GLKit 提供GLKBaseEffect 完成着色器工作(顶点/片元)
        cEffect = GLKBaseEffect()
        cEffect.texture2d0.enabled = GLboolean(GL_TRUE)
        cEffect.texture2d0.name = textureInfo.name
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        // 准备绘制
        cEffect.prepareToDraw()
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
    }
}
