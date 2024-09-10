precision highp float;

attribute vec3 position;
varying vec2 uv;

void main() {
    gl_Position = vec4(position.xyz, 1.0);
    uv = gl_Position.xy;
}
