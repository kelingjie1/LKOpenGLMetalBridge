#version 300 es

in vec2 pos;
in vec2 a_texCoord;
out vec2 v_texCoord;

void main()
{
    gl_Position = vec4(pos,0.,1.);
    v_texCoord = a_texCoord;
}
