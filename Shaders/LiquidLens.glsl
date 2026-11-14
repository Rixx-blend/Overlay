#version 300 es
precision highp float;
precision highp sampler2D;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform sampler2D u_textures[16];

uniform float ior;
uniform float glassThickness;
uniform float dispersion;
uniform float blurRadius;
uniform float refractionStrength;
uniform float edgeLight;
uniform vec4 glassTint;

float roundedBoxDistance(vec2 p, vec2 halfSize, float radius)
{
    vec2 q = abs(p) - (halfSize - vec2(radius));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

float cross2(vec2 a, vec2 b) { return a.x * b.y - a.y * b.x; }

float triangleCoverage(vec2 p, vec2 a, vec2 b, vec2 c)
{
    float area = cross2(b - a, c - a);
    float s1 = cross2(b - a, p - a) / area;
    float s2 = cross2(c - b, p - b) / area;
    float s3 = cross2(a - c, p - c) / area;
    float edge = min(min(s1, s2), s3) * 20.0;
    return smoothstep(0.0, 1.0, edge);
}

float gaussianWeight(int x, int y)
{
    return exp(-0.5 * float(x * x + y * y));
}

float blurredChannel(vec2 pixel, float radius, int channel, vec2 resolution)
{
    float sum = 0.0;
    float weightSum = 0.0;
    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            float w = gaussianWeight(x, y);
            vec2 sampleUv = clamp((pixel + vec2(float(x), float(y)) * radius) / resolution,
                                  vec2(0.001), vec2(0.999));
            sum += texture(u_textures[0], sampleUv)[channel] * w;
            weightSum += w;
        }
    }
    return sum / max(weightSum, 0.0001);
}

void main()
{
    vec2 resolution = max(u_resolution, vec2(1.0));
    vec2 pixel = uv * resolution;

    // Bubble body and its small lower-right speech tail, in overlay pixel space.
    vec2 bodyCenter = vec2(105.0, 105.0);
    float bodyDistance = roundedBoxDistance(pixel - bodyCenter, vec2(97.0, 97.0), 31.0);
    float bodyMask = 1.0 - smoothstep(-1.0, 1.0, bodyDistance);
    float tailMask = triangleCoverage(pixel,
        vec2(190.0, 116.0), vec2(239.0, 135.0), vec2(199.0, 158.0));
    float coverage = max(bodyMask, tailMask);

    if (coverage < 0.002)
    {
        out_color = vec4(0.0);
        return;
    }

    vec2 center = vec2(105.0, 105.0);
    vec2 fromCenter = pixel - center;
    float radial = length(fromCenter);
    vec2 direction = radial > 0.001 ? fromCenter / radial : vec2(0.0);

    // Higher IOR and thickness increase the lens displacement at the curved rim.
    float iorGain = max((ior - 1.0) / max(ior, 1.0), 0.0);
    float rim = 1.0 - smoothstep(0.0, 30.0, max(-bodyDistance, 0.0));
    float lensProfile = pow(clamp(rim, 0.0, 1.0), 1.65);
    float displacement = lensProfile * iorGain * glassThickness
                       * 78.0 * max(refractionStrength, 0.0);
    vec2 refractedPixel = pixel - direction * displacement;

    // Separate red and blue wavelengths in opposite directions near the rim.
    float spectralProfile = pow(clamp(rim, 0.0, 1.0), 1.25);
    float spectralShift = spectralProfile * dispersion * (1.0 + iorGain * 1.4) * 2.2;
    vec2 redPixel = refractedPixel - direction * spectralShift;
    vec2 greenPixel = refractedPixel;
    vec2 bluePixel = refractedPixel + direction * spectralShift;

    float blur = max(blurRadius, 0.0) * (0.35 + 0.65 * spectralProfile);
    vec3 glassColor;
    glassColor.r = blurredChannel(redPixel, blur, 0, resolution);
    glassColor.g = blurredChannel(greenPixel, blur, 1, resolution);
    glassColor.b = blurredChannel(bluePixel, blur, 2, resolution);

    // Subtle cool tint and a Fresnel-like edge reflection.
    glassColor = mix(glassColor, glassTint.rgb, glassTint.a * 0.20);
    float fresnel = pow(clamp(rim, 0.0, 1.0), 2.2) * edgeLight;
    glassColor += vec3(0.58, 0.78, 1.0) * fresnel * 0.20;
    glassColor = clamp(glassColor, 0.0, 1.0);

    out_color = vec4(glassColor * coverage, coverage);
}
