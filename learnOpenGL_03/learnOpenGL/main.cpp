

#include "GLTools.h"
#include <GLUT/glut.h>
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLGeometryTransform.h"
#include "GLFrustum.h"
#include <math.h>

//可变化管线使用矩阵堆栈
GLMatrixStack modelViewMatrix;
GLMatrixStack projectionMatrix;

GLFrame viewFrame;

GLShaderManager shaderManager;
//几何变换的管道
GLGeometryTransform transformPiepeline;
//投影矩阵
GLFrustum viewFrustum;
GLTriangleBatch torusBatch;

//标记：背面剔除、深度测试
int iCull = 0;
int iDepth = 0;

//窗口改变大小，或刚刚创建，都需要重置视口和投影矩阵
void ChangeSize(int w, int h) {
    if (h == 0) {
        h = 1;
    }
    glViewport(0, 0, w, h);
    //创建投影矩阵，并将它载入投影矩阵堆栈中
    viewFrustum.SetPerspective(35.0f, float(w)/float(h), 1.0, 100.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPiepeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpecialKeys(int key, int x, int y) {
    if (key == GLUT_KEY_UP) {
        viewFrame.RotateWorld(m3dDegToRad(-5.0f), 1.0f, 0.0f, 0.0f);
    }
    if (key == GLUT_KEY_DOWN) {
        viewFrame.RotateWorld(m3dDegToRad(5.0), 1.0f, 0.0f, 0.0f);
    }
    if (key == GLUT_KEY_LEFT) {
        viewFrame.RotateWorld(m3dDegToRad(-5.0f), 0.0f, 1.0f, 0.0f);
    }
    if (key == GLUT_KEY_RIGHT) {
        viewFrame.RotateWorld(m3dDegToRad(5.0f), 0.0f, 1.0f, 0.0f);
    }
    glutPostRedisplay();
}


void RenderScene(void) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    if (iCull) {
        glEnable(GL_CULL_FACE);
        glFrontFace(GL_CCW);
        glCullFace(GL_BACK);
    } else {
        glDisable(GL_CULL_FACE);
    }
    
    if (iDepth) {
        glEnable(GL_DEPTH_TEST);
    } else {
        glDisable(GL_DEPTH_TEST);
    }
    
    modelViewMatrix.PushMatrix(viewFrame);
    
    GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
    
    shaderManager.UseStockShader(GLT_SHADER_DEFAULT_LIGHT, transformPiepeline.GetModelViewMatrix(),transformPiepeline.GetProjectionMatrix(),vRed);
    torusBatch.Draw();
    //还原的开始的矩阵
    modelViewMatrix.PopMatrix();
    //交换缓冲区
    glutSwapBuffers();
}

//绘制
void SetupRC() {
    //灰色的背景
    glClearColor(0.7f, 0.7f, 0.7f, 0.7f);
    shaderManager.InitializeStockShaders();
    //将相机向后移动7个单元
    viewFrame.MoveForward(7.0);
    //创建一个甜甜圈
    gltMakeTorus(torusBatch, 1.0f, 0.3f, 52, 26);
    glPointSize(4.0f);//填充点的大小
}

void ProcessMenu(int value) {
    switch (value) {
        case 1:
            iDepth = !iDepth;
            break;
        case 2:
            iCull = !iCull;
            break;
        case 3:
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            break;
        case 4:
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            break;
        case 5:
            glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
            break;
            
        default:
            break;
    }
    glutPostRedisplay();
}

int main(int argc,char* argv[])

{
    //设置gl的工作环境
    gltSetWorkingDirectory(argv[0]);
    //初始化
    glutInit(&argc, argv);
    //GLUT_DOUBLE 双缓存区 GLUT_RGBA 颜色缓存区 GLUT_DEPTH 深度缓存区 GLUT_STENCIL 模板缓存区
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    //设置屏幕的尺寸
    glutInitWindowSize(800, 600);
    //创建window的名称
    glutCreateWindow("Geometry Test program");
    //注册改变尺寸的回调函数
    glutReshapeFunc(ChangeSize);
    //上下左右键位的函数回调
    glutSpecialFunc(SpecialKeys);
    //显示
    glutDisplayFunc(RenderScene);
    
    glutCreateMenu(ProcessMenu);
    
    glutAddMenuEntry("开启深度测试", 1);
    glutAddMenuEntry("正背面剔除", 2);
    glutAddMenuEntry("设置填充模式", 3);
    glutAddMenuEntry("设置线路模式", 4);
    glutAddMenuEntry("设置点模式", 5);
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
    return 0;
}


