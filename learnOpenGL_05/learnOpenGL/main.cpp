

#include "GLTools.h"
#include <GLUT/glut.h>
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLGeometryTransform.h"
#include "GLFrustum.h"
#include <math.h>

GLShaderManager shaderManager;
GLGeometryTransform transformPipeline;
GLBatch floorBatch;
GLMatrixStack modelViewMatrix;
GLMatrixStack projectionMatrix;
GLFrustum viewFrustem;

GLFrame objectFrame;

//窗口改变大小，或刚刚创建，都需要重置视口和投影矩阵
void ChangeSize(int w, int h) {
    glViewport(0, 0, w, h);
    
    //设置视景体
    viewFrustem.SetPerspective(35, float(w)/float(h), 2.0f, 120);
    projectionMatrix.LoadMatrix(viewFrustem.GetProjectionMatrix());
    
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpecialKeys(int key, int x, int y) {
    GLfloat stepSize = 0.025f;
    if (key == GLUT_KEY_UP) {
        
    }
    if (key == GLUT_KEY_DOWN) {
    }
    if (key == GLUT_KEY_LEFT) {
    }
    if (key == GLUT_KEY_RIGHT) {
    }
    
    
    glutPostRedisplay();
}


void RenderScene(void) {
    
    static GLfloat vFloorColor[] = {0.0f,1.0f,0.0,1.0};
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    modelViewMatrix.PushMatrix(objectFrame);
    
    shaderManager.UseStockShader(GLT_SHADER_FLAT,transformPipeline.GetModelViewProjectionMatrix(),vFloorColor);
    floorBatch.Draw();
    
//    modelViewMatrix.PopMatrix();
    //交换缓冲区
    glutSwapBuffers();
//    glutPostRedisplay();
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


