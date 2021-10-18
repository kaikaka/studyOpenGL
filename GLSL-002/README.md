OpenGL ES 加载纹理图片
由于默认加载的图片是倒置的
所以，这个demo写的是5种正确显示图片的方法：
1、///通过读取glsl语法,旋转z轴
    func rotateTextureImage() {
        let rotate = glGetUniformLocation(myPrograme, "rotateMatrix")
        let radians = 180 * Double.pi / 180.0

        let s:GLfloat = GLfloat(sin(radians))
        let c:GLfloat = GLfloat(cos(radians))
        // z轴旋转 open gl es 使用的是列向量
        let zRotation:[GLfloat] = [
            s, c, 0, 0,
            c, -s, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]
        glUniformMatrix4fv(rotate, 1, GLboolean(GL_FALSE), zRotation)
    }
2、//旋转方法2:加载纹理时 旋转图片
        //这句可以不写
        spriteContext?.translateBy(x: 0, y: 0)
        //移动y坐标 然后翻转
        spriteContext?.translateBy(x: 0, y: CGFloat(spriteImage.height))
        spriteContext?.scaleBy(x: 1.0, y: -0.5)
        spriteContext?.translateBy(x: 0, y: 0)
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: spriteImage.width, height: spriteImage.height))
3、在片元着色器修改
    gl_FragColor = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));
    
4、//旋转方法4:重新计算顶点坐标
    varyTextCoord = vec2(textCoordinate.x,1.0-textCoordinate.y);
    vec4 vPos = position;
    vPos = vPos * rotateMatrix;
    gl_Position = vPos;
5、//旋转方法5，坐标系翻转
        let attrArr: [GLfloat] = [
            0.5, -0.5, -1.0, 1.0, 1.0,
            -0.5, 0.5, -1.0, 0.0, 0.0,
            -0.5, -0.5, -1.0, 0.0, 1.0,

            0.5, 0.5, -1.0, 1.0, 0.0,
            -0.5, 0.5, -1.0, 0.0, 0.0,
            0.5, -0.5, -1.0, 1.0, 1.0,
        ]
