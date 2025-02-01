#include "jop_common.fx"

extern float maxDistance = 62000;
extern float outlineThickness = 2.0;
extern float lineTest = 5;
extern float lineDarkMulti = 0.8;
extern float lineDarkMax = 0.1;

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
static const  float xylength = sqrt(1 - eyevec.z * eyevec.z);
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


float4 outline(float2 rawTex : TEXCOORD0) : COLOR
{
    float2 tex = distort(rawTex, time, distortionStrength, sDistortionMap);

    float3 pos = toView(tex, sDepthFrame);
    float dist = length(pos);
    float fog = saturate((fognearrange - dist) / (fognearrange - fognearstart));

    //Thickness decreases by distance
    float clamped_dist = saturate(dist / maxDistance);
    float thickness =  outlineThickness + outlineThickness * (1.0 - clamped_dist);

    float3 offset = float3(rcpres, 0.0) * thickness;
    float lineOffset = timeOffsetMulti * min(distortionStrength, 0.03);
    float2 sceneTex = distort(rawTex, time + lineOffset, distortionStrength, sDistortionMap, lineOffset);
    float4 sceneColor = sample0(sLastShader, sceneTex);

    float sobelDepth = SobelSampleDepth(sDepthFrame, tex.xy, offset);

    float depth = readDepth(tex, sDepthFrame);
    float adjustedLineText = lineTest + (saturate(depth / 25000) * 500);

    sobelDepth = sobelDepth > adjustedLineText ? saturate(sobelDepth) : 0.0;
    sobelDepth = pow(saturate(sobelDepth) * OutlineDepthMultiplier, OutlineDepthBias);
    sobelDepth = step(0.01, sobelDepth);
    float sobelOutline = saturate(sobelDepth);

    float3 outColor = min(sceneColor.rgb * lineDarkMulti, lineDarkMax);

    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    bool aboveWater = water > waterlevel;

    float3 color = lerp(sceneColor.rgb, outColor, sobelOutline * aboveWater);

    return float4(color, sceneColor.a);
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 80;> {
    pass a { PixelShader = compile ps_3_0 outline(); }
}
