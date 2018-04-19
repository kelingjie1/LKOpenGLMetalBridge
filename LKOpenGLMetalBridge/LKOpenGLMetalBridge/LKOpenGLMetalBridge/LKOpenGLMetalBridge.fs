#version 300 es
precision highp float;
in vec2 v_texCoord;
uniform sampler2D tex;
void main()
{
    gl_FragColor = texture(tex,v_texCoord);
}
