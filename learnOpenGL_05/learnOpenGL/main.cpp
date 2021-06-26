

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

#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

//窗口改变大小，或刚刚创建，都需要重置视口和投影矩阵
void ChangeSize(int w, int h) {
    glViewport(0, 0, w, h);
    
    //设置视景体
    viewFrustem.SetPerspective(35, float(w)/float(h), 2.0f, 120);
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


void RenderScene(void) {
    
    static GLfloat vFloorColor[] = {0.0f,1.0f,0.0,1.0};
    static GLfloat vTrousColor[] = {1.0f,0.0f,0.0,1.0};
    static GLfloat vSphereColor[] = {0.0,0.0f,1.0f,1.0f};
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //基于时间的动画
    static CStopWatch rotimer;
    float yRot = rotimer.GetElapsedSeconds() * 60.0;
    
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatrix.PushMatrix(mCamera);
    
    shaderManager.UseStockShader(GLT_SHADER_FLAT,transformPipeline.GetModelViewProjectionMatrix(),vFloorColor);
    floorBatch.Draw();
    
    //光源
    M3DVector4f vlightPos = {0.0,10.0,5.0,1.0f};
    modelViewMatrix.Translate(0.0, 0.0, -3.0);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot, 0.0, 1.0, 0.0);
    shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF,transformPipeline.GetModelViewMatrix(),transformPipeline.GetProjectionMatrix(),vlightPos,vTrousColor);
    torusBatch.Draw();
    modelViewMatrix.PopMatrix();
    
    //画小球
    for (int i = 0;i < NUM_SPHERES; i ++) {
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF,transformPipeline.GetModelViewMatrix(),transformPipeline.GetProjectionMatrix(),vlightPos,vSphereColor);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot * -2.0f, 0.0f, 1.0f, 0.0f);
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_FLAT,transformPipeline.GetModelViewProjectionMatrix(),vSphereColor);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();
    
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

    //先绘制地板
    floorBatch.Begin(GL_LINES, 300);
    for (GLfloat x = -20.0; x <= 20.0f; x += 0.5) {
        floorBatch.Vertex3f(x, -0.55f, 20.0f);
        floorBatch.Vertex3f(x, -0.55, -30.0f);
        
        floorBatch.Vertex3f(20.0, -0.55f, x);
        floorBatch.Vertex3f(-20.0, -0.55f, x);
    }
    floorBatch.End();
    
    //大球
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    
    //小球
    gltMakeSphere(sphereBatch, 0.1, 26, 13);
    
    for (int i = 0;i < NUM_SPHERES ; i++) {
        //只改变x，z轴的值
        GLfloat x = ((GLfloat)((rand() % 400) - 300) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 300) * 0.1);
        //设置顶点数据
        spheres[i].SetOrigin(x,0.0,z);
    }
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
    glutCreateWindow("OenGl");
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
    return 0;
}


