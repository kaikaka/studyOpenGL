

#include "GLTools.h"
#include <GLUT/glut.h>
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLGeometryTransform.h"
#include "GLFrustum.h"
#include <math.h>
#include "GLBatch.h"
#include "StopWatch.h"

#define TEXTURE_COUNT 3 //纹理个数

GLFrustum viewFrustum;
GLMatrixStack modelViewMatrix;
GLMatrixStack projectionMatrix;
GLGeometryTransform transformPipeline;
GLShaderManager shaderManager;

GLuint textures[TEXTURE_COUNT];
const char *szTextureFiles[TEXTURE_COUNT] = {"brick.tga","floor.tga","ceiling.tga"};

GLBatch floorBatch;//地面
GLBatch ceilingBatch;//天花版
GLBatch leftWallBatch;//左墙面
GLBatch rightWallBatch;//右墙面

GLfloat viewZ = -65.0f;

#define TEXTURE_BRICK 0//墙面
#define TEXTURE_FLOOR 1//地板
#define TEXTURE_CeilingBatch 2//纹理天花板

void ChangeSize(int w, int h) {
    if (h == 0)
        h = 1;
    glViewport(0, 0, w, h);
    viewFrustum.SetPerspective(80.0f, float(w) / float(h), 1.0f, 120.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpecialKeys(int key, int x, int y) {
    
    if (key == GLUT_KEY_UP) {
        viewZ += 0.5f;
    }
    if (key == GLUT_KEY_DOWN) {
        viewZ -= 0.5f;
    }
    glutPostRedisplay();
}


void RenderScene(void) {
    glClear(GL_COLOR_BUFFER_BIT);
    
    modelViewMatrix.PushMatrix();
    
    modelViewMatrix.Translate(0.0f, 0.0f, viewZ);
    
    /*纹理替换矩阵着色器
     参数1：GLT_SHADER_TEXTURE_REPLACE（着色器标签）
     参数2：模型视图投影矩阵
     参数3：纹理层
     */
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE,transformPipeline.GetModelViewProjectionMatrix(),0);
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_FLOOR]);
    floorBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_CeilingBatch]);
    ceilingBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_BRICK]);
    leftWallBatch.Draw();
    rightWallBatch.Draw();
    
    modelViewMatrix.PopMatrix();
    glutSwapBuffers();
}


//绘制
void SetupRC() {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    
    GLbyte *pBytes;
    GLint iWidth, iHeight , iComponent;
    GLenum eFromat;
    GLint iLoop;
    
    //分配纹理对象，TEXTURE_COUNT 纹理对象的数量，textures纹理对象标识数组
    glGenTextures(TEXTURE_COUNT, textures);
    
//    循环设置纹理数组的纹理参数
    for (iLoop = 0; iLoop < TEXTURE_COUNT; iLoop++) {
        glBindTexture(GL_TEXTURE_2D, textures[iLoop]);
        pBytes = gltReadTGABits(szTextureFiles[iLoop], &iWidth, &iHeight, &iComponent, &eFromat);
//        加载纹理、设置过滤器和包装模式
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//        GL_TEXTURE_MAG_FILTER（放大过滤器,GL_NEAREST(最邻近过滤)GL_TEXTURE_MIN_FILTER(缩小过滤器)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//        GL_TEXTURE_WRAP_S(s轴环绕),GL_CLAMP_TO_EDGE(环绕模式强制对范围之外的纹理坐标沿着合法的纹理单元的最后一行或一列进行采样)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//        GL_TEXTURE_WRAP_T(t轴环绕)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        /**载入纹理 glTexImage2D
         参数1：纹理维度，GL_TEXTURE_2D
         参数2：mip贴图层次
         参数3：纹理单元存储的颜色成分（从读取像素图中获得）
         参数4：加载纹理宽度
         参数5：加载纹理的高度
         参数6：加载纹理的深度
         参数7：像素数据的数据类型,GL_UNSIGNED_BYTE无符号整型
         参数8：指向纹理图像数据的指针
         */
        glTexImage2D(GL_TEXTURE_2D, 0, iComponent, iWidth, iHeight, 0, eFromat, GL_UNSIGNED_BYTE, pBytes);
        //生成完整的mipmap
        glGenerateMipmap(GL_TEXTURE_2D);
        free(pBytes);
    }
    GLfloat z;
    floorBatch.Begin(GL_TRIANGLE_STRIP, 28,1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z);
        
        floorBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z);
        
        floorBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
        
        floorBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
    }
    floorBatch.End();
    
    ceilingBatch.Begin(GL_TRIANGLE_STRIP, 28,1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        ceilingBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z);
        
        ceilingBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z);
        
        ceilingBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
        
        ceilingBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
    }
    ceilingBatch.End();
    
    leftWallBatch.Begin(GL_TRIANGLE_STRIP, 28,1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        leftWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        leftWallBatch.Vertex3f(-10.0f, -10.0f, z);
        
        leftWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        leftWallBatch.Vertex3f(-10.0f, 10.0f, z);
        
        leftWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        leftWallBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
        
        leftWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        leftWallBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
    }
    leftWallBatch.End();
    
    rightWallBatch.Begin(GL_TRIANGLE_STRIP, 28,1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        rightWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        rightWallBatch.Vertex3f(10.0f, -10.0f, z);
        
        rightWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        rightWallBatch.Vertex3f(10.0f, 10.0f, z);
        
        rightWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        rightWallBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
        
        rightWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        rightWallBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
    }
    rightWallBatch.End();
    
}

// 清理…例如删除纹理对象
void ShutdownRC(void)
{
    glDeleteTextures(TEXTURE_COUNT, textures);
}

void ProcessMenu(int value) {
    GLint iLoop;
    
    for(iLoop = 0; iLoop < TEXTURE_COUNT; iLoop++)
    {
        /**绑定纹理 glBindTexture
         参数1：GL_TEXTURE_2D
         参数2：需要绑定的纹理对象
         */
        glBindTexture(GL_TEXTURE_2D, textures[iLoop]);
        
        /**配置纹理参数 glTexParameteri
         参数1：纹理模式
         参数2：纹理参数
         参数3：特定纹理参数
         
         */
        switch(value)
        {
            case 0:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_NEAREST（最邻近过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                break;
                
            case 1:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_LINEAR（线性过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                break;
                
            case 2:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_NEAREST_MIPMAP_NEAREST（选择最邻近的Mip层，并执行最邻近过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
                break;
                
            case 3:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_NEAREST_MIPMAP_LINEAR（在Mip层之间执行线性插补，并执行最邻近过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
                break;
                
            case 4:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_NEAREST_MIPMAP_LINEAR（选择最邻近Mip层，并执行线性过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
                break;
                
            case 5:
                //GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER(缩小过滤器)，GL_LINEAR_MIPMAP_LINEAR（在Mip层之间执行线性插补，并执行线性过滤，又称为三线性过滤）
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                break;
                
            case 6:
            
                //设置各向异性过滤
                GLfloat fLargest;
                //获取各向异性过滤的最大数量
                glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &fLargest);
                //设置纹理参数(各向异性采样)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, fLargest);
                break;
        
            case 7:
                //设置各向同性过滤，数量为1.0表示(各向同性采样)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
                break;
                
        }
    }
    
    //触发重画
    glutPostRedisplay();
}

int main(int argc,char* argv[])

{
    //设置gl的工作环境
    gltSetWorkingDirectory(argv[0]);
    //初始化
    glutInit(&argc, argv);
    //GLUT_DOUBLE 双缓存区 GLUT_RGBA 颜色缓存区
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    //设置屏幕的尺寸
    glutInitWindowSize(800, 600);
    //创建window的名称
    glutCreateWindow("隧道");
    //注册改变尺寸的回调函数
    glutReshapeFunc(ChangeSize);
    //上下左右键位的函数回调
    glutSpecialFunc(SpecialKeys);
    //显示
    glutDisplayFunc(RenderScene);
    
    //压缩方式
    glutCreateMenu(ProcessMenu);
    glutAddMenuEntry("最邻近过滤",0);
    glutAddMenuEntry("线性过滤",1);
    glutAddMenuEntry("邻近Mip层邻近过滤",2);
    glutAddMenuEntry("Mip层之间执⾏行行线性插补最邻近过滤", 3);
    glutAddMenuEntry("选择最邻近Mip层，并执⾏行行线性过滤", 4);
    glutAddMenuEntry("三线性Mip贴图", 5);
    glutAddMenuEntry("各向异性 过滤", 6);
    glutAddMenuEntry("Anisotropic Off", 7);
    
    
    glutAttachMenu(GLUT_RIGHT_BUTTON);
    
    GLenum err = glewInit();
    if (err != GLEW_OK) {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    //绘制
    SetupRC();
    //进入循环
    glutMainLoop();
    
    ShutdownRC();
    return 0;
}


