

#include "GLTools.h"
#include <GLUT/glut.h>
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLGeometryTransform.h"
#include "GLFrustum.h"
#include <math.h>
#include "GLBatch.h"
#include "StopWatch.h"

GLShaderManager shaderManager;
GLGeometryTransform transformPipeline;
GLBatch floorBatch;
GLTriangleBatch torusBatch;
GLTriangleBatch sphereBatch;

GLMatrixStack modelViewMatrix;
GLMatrixStack projectionMatrix;
GLFrustum viewFrustem;

GLFrame cameraFrame;
GLuint uiTextures[3];

#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

bool LoadTGATexture(const char *szFileName,GLenum minFilter,GLenum magFilter,GLenum wrapMode) {
    GLbyte *pBits;
    int nWidth, nHeight,nComponents;
    GLenum eFormat;
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    if (pBits == NULL)
        return  false;
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB, nWidth, nHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBits);
    
    free(pBits);
    
    if (minFilter == GL_LINEAR_MIPMAP_LINEAR || minFilter == GL_LINEAR_MIPMAP_NEAREST ||
        minFilter == GL_NEAREST_MIPMAP_LINEAR || minFilter == GL_NEAREST_MIPMAP_NEAREST) {
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    
    return true;
}

//窗口改变大小，或刚刚创建，都需要重置视口和投影矩阵
void ChangeSize(int w, int h) {
    glViewport(0, 0, w, h);
    
    //设置视景体
    viewFrustem.SetPerspective(35, float(w)/float(h), 1.0f, 120);
    projectionMatrix.LoadMatrix(viewFrustem.GetProjectionMatrix());
    
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpecialKeys(int key, int x, int y) {
    float linear = 0.1f;
    float angular = float(m3dDegToRad(5.0f));
    
    if (key == GLUT_KEY_UP) {
        cameraFrame.MoveForward(linear);
    }
    if (key == GLUT_KEY_DOWN) {
        cameraFrame.MoveForward(-linear);
    }
    if (key == GLUT_KEY_LEFT) {
        cameraFrame.RotateWorld(angular, 0.0, 1.0, 0.0f);
    }
    if (key == GLUT_KEY_RIGHT) {
        cameraFrame.RotateWorld(-angular, 0.0, 1.0, 0.0f);
    }
    
}

void drawFace(GLfloat yRot) {
    static GLfloat vTrousColor[] = {1.0f,1.0f,1.0,1.0};
    static GLfloat vSphereColor[] = {1.0f,1.0f,1.0,1.0};
    //光源
    M3DVector4f vlightPos = {0.0,3.0,0.0,1.0f};
    
    modelViewMatrix.Translate(0.0, 0.0, -3.0);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot, 0.0, 1.0, 0.0);
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,modelViewMatrix.GetMatrix(),transformPipeline.GetProjectionMatrix(),vlightPos,vTrousColor,0);
    torusBatch.Draw();
    modelViewMatrix.PopMatrix();
    
    //画小球
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    for (int i = 0;i < NUM_SPHERES; i ++) {
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,modelViewMatrix.GetMatrix(),transformPipeline.GetProjectionMatrix(),vlightPos,vSphereColor,0);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot * -2.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,modelViewMatrix.GetMatrix(),transformPipeline.GetProjectionMatrix(),vlightPos,vSphereColor,0);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();
}


void RenderScene(void) {
    
    static GLfloat vFloorColor[] = {1.0f,1.0f,0.0,1.0};
    
    //基于时间的动画
    static CStopWatch rotimer;
    float yRot = rotimer.GetElapsedSeconds() * 60.0;
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    modelViewMatrix.PushMatrix();
    
    
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatrix.MultMatrix(mCamera);
    
    modelViewMatrix.PushMatrix(mCamera);
    
    modelViewMatrix.Scale(1.0f, -1.0f, 1.0f);
    modelViewMatrix.Translate(0.0f, 0.8f, 0.0f);
    //指定顺时针为正面
    glFrontFace(GL_CW);
    drawFace(yRot);
    //恢复逆时针为正面
    glFrontFace(GL_CCW);
    modelViewMatrix.PopMatrix();
    
    
    //开启混合功能
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_MODULATE,transformPipeline.GetModelViewProjectionMatrix(),vFloorColor,0);
    floorBatch.Draw();
    glDisable(GL_BLEND);
    
    drawFace(yRot);
   
    
    modelViewMatrix.PopMatrix();
    //交换缓冲区
    glutSwapBuffers();
    glutPostRedisplay();
}

//绘制
void SetupRC() {
    //灰色的背景
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    //大球
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    
    //小球
    gltMakeSphere(sphereBatch, 0.1, 26, 13);
    
    //先绘制地板
    floorBatch.Begin(GL_LINES, 300);
    for (GLfloat x = -20.0; x <= 20.0f; x += 0.5) {
        floorBatch.Vertex3f(x, -0.55f, 20.0f);
        floorBatch.Vertex3f(x, -0.55, -30.0f);
        
        floorBatch.Vertex3f(20.0, -0.55f, x);
        floorBatch.Vertex3f(-20.0, -0.55f, x);
    }
    floorBatch.End();
    
    for (int i = 0;i < NUM_SPHERES ; i++) {
        //只改变x，z轴的值
        GLfloat x = ((GLfloat)((rand() % 400) - 300) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 300) * 0.1);
        //设置顶点数据
        spheres[i].SetOrigin(x,0.0,z);
    }
    
    glGenTextures(3, uiTextures);
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    LoadTGATexture("Marble.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_REPEAT);
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    LoadTGATexture("Marslike.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    LoadTGATexture("Moonlike.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE);
}

//删除纹理
void ShutdownRC(void)
{
    glDeleteTextures(3, uiTextures);
}


int main(int argc,char* argv[])

{
    //设置gl的工作环境
    gltSetWorkingDirectory(argv[0]);
    //初始化
    glutInit(&argc, argv);
    //GLUT_DOUBLE 双缓存区 GLUT_RGBA 颜色缓存区 GLUT_DEPTH 深度缓存区 GLUT_STENCIL 模板缓存区
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
    //设置屏幕的尺寸
    glutInitWindowSize(800, 600);
    //创建window的名称
    glutCreateWindow("火星");
    //注册改变尺寸的回调函数
    glutReshapeFunc(ChangeSize);
    //上下左右键位的函数回调
    glutSpecialFunc(SpecialKeys);
    //显示
    glutDisplayFunc(RenderScene);
    
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


