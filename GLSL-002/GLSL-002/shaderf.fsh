precision highp float;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main() {
    gl_FragColor = texture2D(colorMap, varyTextCoord);
//    图片旋转的第3个方法：片元着色器时重计算顶点
//    gl_FragColor = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));
}
