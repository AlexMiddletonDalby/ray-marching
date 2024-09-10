precision highp float;

uniform float time;
uniform float audioRunningTime;
uniform float rms;

uniform float lows;
uniform float mids;
uniform float highs;

varying vec2 uv;
uniform vec2 resolution;

const float MIN_DEPTH = 0.001;
const float MAX_DEPTH = 100.0;
const float MAX_STEPS = 100.0;

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

float sdSphere(vec3 p, float s)
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

vec3 opTwist(in vec3 p, float k)
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2 m = mat2(c,-s,s,c);
    vec3 q = vec3(m*p.xz,p.y);
    return q;
}

float displacement(vec3 p)
{
    return sin(20.0 * p.x) * sin(20.0 * p.y) * sin(20.0 * p.z);
}

float spinningOctas(vec3 p)
{
    float twistiness = rms * 0.8 + (highs * 1000.0);
    float bigness = rms * 0.3 + pow(mids * 0.005, 0.9);
    float splatiness = lows * 0.00025;

    vec3 spaceRepeatedP = fract(p) - 0.5;
   // vec3 spaceRepeatedP = p;

    vec3 octaPostion = vec3(0.0, 0.0, 0.0);
    vec3 octa = spaceRepeatedP + octaPostion;
    octa.xz *= rotate(time);
    octa = opTwist (opTwist(octa, twistiness), 1.0 - twistiness);
    octa += displacement(p) * splatiness;
    float octahedron = sdOctahedron(octa, 0.25 + bigness);

    vec3 spherePosition = vec3(sin(time) * 0.2, cos(time) * 0.1, 0.0);
    float sphere = sdSphere(spaceRepeatedP - spherePosition, 0.0);

    return smin(octahedron, sphere, 0.01);
}

struct Raymarch
{
    float depth;
    float iterations;
    bool hit;
    bool missed;
};

Raymarch raymarchScene(in vec3 rayOrigin, in vec3 rayDirection, vec3 wobble)
{
    Raymarch march;

    vec3 outputColour = vec3(0.0, 0.0, 0.0);
    for (float step = 0.0; step < MAX_STEPS; step += 1.0)
    {
        vec3 rayPos = rayOrigin + rayDirection * march.depth;
        rayPos.y += sin(march.depth) * 0.5;
        rayPos.x += cos(march.depth) * 0.5;

        float distToScene = spinningOctas(rayPos);

        march.depth += distToScene;
        march.iterations = step;

        if (march.depth > MAX_DEPTH || distToScene < MIN_DEPTH)
        {
            if (march.depth > MAX_DEPTH)
            {
                march.missed = true;
            }
            if (distToScene < MIN_DEPTH)
            {
                march.hit = true;
            }

            return march;
        }
    }

    return march;
}

vec3 palette( in float posOnPalette, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*posOnPalette+d) );
}

void main() {
    //Correct UV for aspect ratio
    float aspectRatio = resolution.x / resolution.y;
    vec2 correctedUv = vec2(uv.x * aspectRatio, uv.y);

    //Set up camera
    vec3 cameraPosition = vec3(0.0, 0.0, -0.7);
    cameraPosition += vec3(0.0, 0.0, audioRunningTime * 0.9);

    //Set up ray
    vec3 rayDirection = normalize(vec3(correctedUv, 1.0));
    rayDirection.xy *= rotate(time * 0.1);

    vec3 rayOrigin = cameraPosition;

    //March the scene
    Raymarch march = raymarchScene(rayOrigin, rayDirection, vec3(0.0, 0.0, 0.0));

    //Colourise pixels
    float brightness = max (0.1, rms * 4.0);

    float glow = march.iterations / MAX_STEPS;
    float depth = march.depth * 0.4;

    vec3 baseColour = palette ((sin(time) * 0.3),
                               vec3(0.5, 0.5, 0.5),
                               vec3(0.5, 0.5, 0.5),
                               vec3(1.0, 1.0, 0.0),
                               vec3(0.3, 0.2, 0.0));

    vec3 colour = vec3(depth * baseColour);

    if (march.hit)
    {
        colour += (glow * 0.8) + 1.0;
    }

    vec3 ambient = vec3(0.2, 0.4, 0.3) * 0.1;

    gl_FragColor = vec4((colour * brightness) + ambient, 1.0);

}
