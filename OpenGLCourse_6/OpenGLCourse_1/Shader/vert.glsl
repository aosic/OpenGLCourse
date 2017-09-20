attribute vec4 position;
attribute vec2 color;

uniform float elapsedTime;
uniform mat4 transform;

varying vec2 vTexcoord;

void main()
{
    gl_Position = transform * position;
    vTexcoord = color;
}
