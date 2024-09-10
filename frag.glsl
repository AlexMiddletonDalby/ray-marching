precision highp float;

uniform float time;
varying vec2 uv;

float sphereSdf(vec3 p, float s)
{
    return length(p) - s;
}

float sceneSdf(vec3 p)
{
    vec3 spherePosition = vec3(sin(time) * 1.5, 0.0, cos(time) * 1.5);
    float sphere1 = sphereSdf(p, 1.0);
    float sphere2 = sphereSdf(p - spherePosition, 0.3);

    return min(sphere1, sphere2);
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
    const float maxRayMarchingSteps = 60.0;

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
    vec3 rayDirection = normalize(vec3(uv, 1.0));

    vec3 rayOrigin = cameraPosition;

    Raymarch march = raymarchScene(rayOrigin, rayDirection);

    float glow = march.iterations / 60.0;
    float col = march.depth * 0.2;
    gl_FragColor = vec4(vec3(col + (glow * 0.3)), 1.0);
}
