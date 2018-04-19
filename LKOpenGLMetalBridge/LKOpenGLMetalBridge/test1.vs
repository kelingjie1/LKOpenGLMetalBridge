#version 300 es

in vec2 pos;
in vec2 a_texCoord;

out vec2 v_texCoord;
void main()
{
    v_texCoord = a_texCoord;
    gl_Position = vec4(pos,0.,1.);
}
