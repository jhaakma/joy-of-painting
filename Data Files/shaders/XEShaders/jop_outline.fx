#include "jop_common.fx"

extern float maxDistance = 62000;
extern float outlineThickness = 2;
extern float lineTest = 5;
extern float lineDarkMulti = 0.1;
extern float lineDarkMax = 0.1;
extern float fadePerlinScale = 5;

extern float timeOffsetMulti = 0.0;
extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion

texture lastshader;
texture depthframe;
texture lastpass;
texture tex1 < string src="jop/perlinNoise.tga"; >; // Your normal map texture

sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point;};
sampler sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point;};
sampler sLastShader = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDistortionMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

static float fogoffset = saturate(-fogstart / (fogrange - fogstart));
float OutlineDepthMultiplier = 1.0;
float OutlineDepthBias = 1.0;


float LinearEyeDepth(float z) {
    float c = mproj._33;
    float e = mproj._43;
    float near = -e / c;
    float far = -((c * near) / (1 - c));
    float eyeDepth = far * near / ((near - far) * z + far);
    return (z);
}

float SobelDepth(float ldc, float ldl, float ldr, float ldu, float ldd) {
    return (ldl - ldc) +
           (ldr - ldc) +
           (ldu - ldc) +
           (ldd - ldc);
}

float SobelSampleDepth(sampler s, float2 uv, float3 offset) {
    float pixelCenter = LinearEyeDepth(sample0(s, uv).r);
    float pixelLeft = LinearEyeDepth(sample0(s, uv - offset.xz).r);
    float pixelRight = LinearEyeDepth(sample0(s, uv + offset.xz).r);
    float pixelUp = LinearEyeDepth(sample0(s, uv + offset.zy).r);
    float pixelDown = LinearEyeDepth(sample0(s, uv - offset.zy).r);

    return SobelDepth(pixelCenter, pixelLeft, pixelRight, pixelUp, pixelDown);
}


float calculateFog(float3 pos, float fognearstart, float fognearrange) {
    float dist = length(pos);
    return saturate((fognearrange - dist) / (fognearrange - fognearstart));
}

float calculateThickness(float dist, float maxDistance, float outlineThickness) {
    float clamped_dist = saturate(dist / maxDistance);
    return outlineThickness + outlineThickness * (1.0 - clamped_dist);
}

float4 sampleSceneColor(float2 rawTex, float Time, float distortionStrength, sampler sDistortionMap, float timeOffsetMulti, sampler sLastShader) {
    float lineOffset = timeOffsetMulti * min(distortionStrength, 0.03);
    float2 sceneTex = distort(rawTex, distortionStrength, sDistortionMap, lineOffset);
    return sample0(sLastShader, sceneTex);
}

float calculateSobelOutline(float sobelDepth, float depth, float lineTest, float OutlineDepthMultiplier, float OutlineDepthBias) {
    float adjustedLineText = lineTest + (saturate(depth / 25000) * 500);
    sobelDepth = sobelDepth > adjustedLineText ? saturate(sobelDepth) : 0.0;
    sobelDepth = pow(saturate(sobelDepth) * OutlineDepthMultiplier, OutlineDepthBias);
    return step(0.01, sobelDepth);
}

float getFadeStrength(float2 Tex) {
    float2 uv = float2(Tex.x + sin(Time * 0.5) * 0.1, Tex.y + cos(Time * 0.5) * 0.1) / 4.0;
    float4 normalMap = tex2D(sDistortionMap, uv * fadePerlinScale);
    float fadeStrength = normalMap.b;
    return saturate(fadeStrength - 0.2);
}


float getOutline(float2 tex, float3 pos, float thickness, float depth) {
    float3 offset = float3(rcpres, 0.0) * thickness;
    float4 sceneColor = sampleSceneColor(tex, Time, distortionStrength, sDistortionMap, timeOffsetMulti, sLastShader);

    float sobelDepth = SobelSampleDepth(sDepthFrame, tex.xy, offset);
    float sobelOutline = calculateSobelOutline(sobelDepth, depth, lineTest, OutlineDepthMultiplier, OutlineDepthBias);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    bool aboveWater = water > waterlevel;
    sobelOutline = sobelOutline * aboveWater;

    return sobelOutline;
}


float4 outline(float2 rawTex : TEXCOORD0) : COLOR {
    float2 tex = distort(rawTex, distortionStrength, sDistortionMap);
    float3 pos = toView(tex, sDepthFrame);
    float fog = calculateFog(pos, fognearstart, fognearrange);

    float fadeStrength1 = getFadeStrength(rawTex) * 2;
    float thickness1 = calculateThickness(length(pos), maxDistance, outlineThickness);
    thickness1 = thickness1 * fadeStrength1;
    float depth = readDepth(tex, sDepthFrame);
    float3 outline1 = getOutline(tex, pos, thickness1, depth);

    float4 sceneColor = sampleSceneColor(rawTex, Time, distortionStrength, sDistortionMap, timeOffsetMulti, sLastShader);
    float3 lineColor = min(sceneColor.rgb * lineDarkMulti, lineDarkMax);

    float3 color = lerp(sceneColor.rgb, lineColor, outline1);

    return float4(color, sceneColor.a);
}

float4 getFadeStrengthTest(float2 Tex : TEXCOORD0) : COLOR {
    float fadeStrength = getFadeStrength(Tex);
    return float4(fadeStrength, fadeStrength, fadeStrength, 1);
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 80;> {
    pass a { PixelShader = compile ps_3_0 outline(); }
}
