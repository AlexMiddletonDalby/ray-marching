precision highp float;

uniform float time;
varying vec2 uv;
uniform vec2 resolution;

mat2 rotate(float a)
{
    float s = sin(a);
    float c = cos(a);

    return mat2(c, -s, s, c);
}

float smin( float a, float b, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

float sphereSdf(vec3 p, float s)
{
    return length(p) - s;
}

float sdOctahedron(vec3 p, float s)
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

vec3 opTwist(in vec3 p)
{
    const float k = 25.0;
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2 m = mat2(c,-s,s,c);
    vec3 q = vec3(m*p.xz,p.y);
    return q;
}

float sceneSdf(vec3 p)
{
    vec3 spaceRepeatedP = fract(p) - 0.5;

    vec3 octaPostion = vec3(sin(p.z+time)*0.08, 0.0, 0.0);
    vec3 octa = spaceRepeatedP + octaPostion;
    octa.xz *= rotate(time);
    octa = opTwist(octa);
    float octahedron = sdOctahedron(octa, 0.25);

    vec3 spherePosition = vec3(sin(time) * 1.5, 0.0, cos(time) * 1.5);
    float sphere = sphereSdf(spaceRepeatedP - spherePosition, 0.25);

    return smin(octahedron, sphere, 0.4);
}

struct Raymarch
{
    float depth;
    float iterations;
};

Raymarch raymarchScene(in vec3 rayOrigin, in vec3 rayDirection)
{
    Raymarch march;

    const float minDepth = 0.001;
    const float maxDepth = 100.0;
    const float maxRayMarchingSteps = 200.0;

    vec3 outputColour = vec3(0.0, 0.0, 0.0);
    for (float step = 0.0; step < maxRayMarchingSteps; step += 1.0)
    {
        vec3 rayPos = rayOrigin + rayDirection * march.depth;
        float distToScene = sceneSdf(rayPos);

        march.depth += distToScene;
        march.iterations = step;

        if (march.depth > maxDepth || distToScene < minDepth)
        {
            return march;
        }
    }

    return march;
}

void main() {
    vec3 cameraPosition = vec3(0.0, 0.0, -3.0);
    cameraPosition += vec3(0.0, 0.0, time * 0.5);

    float aspectRatio = resolution.x / resolution.y;
    vec2 correctedUv = vec2(uv.x * aspectRatio, uv.y);

    vec3 rayDirection = normalize(vec3(correctedUv, 1.0));

    vec3 rayOrigin = cameraPosition;

    Raymarch march = raymarchScene(rayOrigin, rayDirection);

    float glow = march.iterations / 60.0;
    float col = march.depth * 0.3;
    gl_FragColor = vec4(vec3(col, col - 0.5, glow + col), 1.0);
}
