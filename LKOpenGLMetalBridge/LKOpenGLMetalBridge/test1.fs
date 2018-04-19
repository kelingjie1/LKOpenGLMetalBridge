#version 300 es
precision highp float;
uniform sampler2D tex;
in vec2 v_texCoord;
out vec4 color;
void main()
{
    color = texture(tex,v_texCoord);
}
