attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;
//uniform mat4 rotateMatrix;

void main() {
    varyTextCoord = textCoordinate;
    //旋转方法4:重新计算顶点坐标
//    varyTextCoord = vec2(textCoordinate.x,1.0-textCoordinate.y);
//    vec4 vPos = position;
//    vPos = vPos * rotateMatrix;
//    gl_Position = vPos;
    gl_Position = position;
}
