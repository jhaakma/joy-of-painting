#include "jop_common.fx"
#include "jop_gaussian.fx"

extern float maxDistance = 62000;
extern float outlineThickness = 2;
extern float lineTest = 5;
extern float lineDarkMulti = 0.05;
extern float lineDarkMax = 0.1;
extern float fadePerlinScale = 5;
extern float normalOutlineThreshold = 5;
extern float shadow = 0.1;

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

// Calculate the fog factor based on the distance from the camera
float calculateFog(float3 pos, float fognearstart, float fognearrange) {
    float dist = length(pos);
    return saturate((fognearrange - dist) / (fognearrange - fognearstart));
}

float calculateThickness(float dist, float maxDistance, float outlineThickness) {
    float clamped_dist = saturate(dist / maxDistance);
    return outlineThickness + outlineThickness * (1.0 - clamped_dist);
}

float4 sampleSceneColor(float2 rawTex, float Time, float distStrength, sampler distMap, float timeOffsetMulti, sampler shaderMap) {
    float lineOffset = timeOffsetMulti * min(distStrength, 0.03);
    float2 sceneTex = distort(rawTex, distStrength, distMap, lineOffset);
    return sample0(shaderMap, sceneTex);
}

float calculateSobelOutline(float sobelDepth, float depth, float lineTest, float OutlineDepthMultiplier, float OutlineDepthBias) {
    float adjustedLineText = lineTest + (saturate(depth / 25000) * 500);
    sobelDepth = sobelDepth > adjustedLineText ? saturate(sobelDepth) : 0.0;
    sobelDepth = pow(saturate(sobelDepth) * OutlineDepthMultiplier, OutlineDepthBias);
    return step(0.01, sobelDepth);
}

float getFadeStrength(float2 Tex) {
    float2 uv = float2(Tex.x + sin(Time * 0.1) * 0.1, Tex.y + cos(Time * 0.1) * 0.1) / 4.0;
    float4 normalMap = tex2D(sDistortionMap, uv * fadePerlinScale);
    float fadeStrength = normalMap.r;

    return saturate(fadeStrength * 1.5 - 0.3);
}


float getSobelOutline(float2 tex, float3 pos, float thickness, float depth) {
    float3 offset = float3(rcpres, 0.0) * thickness;

    float sobelDepth = SobelSampleDepth(sDepthFrame, tex.xy, offset);
    float sobelOutline = calculateSobelOutline(sobelDepth, depth, lineTest, OutlineDepthMultiplier, OutlineDepthBias);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    bool aboveWater = water > waterlevel;
    sobelOutline = sobelOutline * aboveWater;

    return sobelOutline;
}


/**
    Sample the normals around the position with getWorldSpaceNormal
    If the normals change too much, it's an edge
    Use the threshold value to change how much the normals need to change
**/
float getNormalsOutline(float2 tex, float3 pos, float thickness, float depth, float threshold) {
    float3 normalCenter = getWorldSpaceNormal(tex, sDepthFrame);
    float3 normalDiff = float3(0.0, 0.0, 0.0);

    // Apply Gaussian smoothing using a circular kernel
    for (int x = -4; x <= 4; x++) {
        for (int y = -4; y <= 4; y++) {
            if (x*x + y*y <= 16) { // Circular mask with radius 4
                float weight = kernelRad4[x + 4][y + 4];
                float2 offset = float2(x, y) * rcpres * thickness;
                float3 sampledNormal = getWorldSpaceNormal(tex + offset, sDepthFrame);
                normalDiff += abs(sampledNormal - normalCenter) * weight;
            }
        }
    }

    float normalOutline = step(threshold, dot(normalDiff, float3(1, 1, 1)));
    return normalOutline;
}


float calculateLuminosity(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}


float SobelSampleLuminosity(sampler s, float2 uv, float3 offset) {
    float3 colorCenter = sample0(s, uv).rgb;
    float3 colorLeft = sample0(s, uv - offset.xz).rgb;
    float3 colorRight = sample0(s, uv + offset.xz).rgb;
    float3 colorUp = sample0(s, uv + offset.zy).rgb;
    float3 colorDown = sample0(s, uv - offset.zy).rgb;

    float lumCenter = RGBToHSL(colorCenter).x;
    float lumLeft = RGBToHSL(colorLeft).x;
    float lumRight = RGBToHSL(colorRight).x;
    float lumUp = RGBToHSL(colorUp).x;
    float lumDown = RGBToHSL(colorDown).x;

    return SobelDepth(lumCenter, lumLeft, lumRight, lumUp, lumDown);
}

float4 getShadow(float2 tex, float4 color)
{
    // Define the thresholds for the limited band shades
    float darkGrayThreshold = shadow;
    float fadeThreshold = darkGrayThreshold + 0.01;
    float average = dot(color.rgb, float3(0.299, 0.587, 0.114));

    float black = 0.0;
    float white = 0.99;

    // Quantize the average value to the limited band of shades
    if (average < darkGrayThreshold) {
        color.rgb = float3(white, white, white);
    } else if (average < fadeThreshold) {
        float smoothDecay = saturate((average - darkGrayThreshold) / (fadeThreshold - darkGrayThreshold));
        float grey = lerp(white, black, smoothDecay);
        color.rgb = float3(grey, grey, grey);
    } else {
        color.rgb = float3(black, black, black);
    }


    return color;
}

float getOutline(float2 tex, float3 pos, float thickness, float depth) {
    float sobelOutline = getSobelOutline(tex, pos, thickness, depth);
    float normalOutline = getNormalsOutline(tex, pos, thickness, depth, normalOutlineThreshold);


    float4 color = tex2D(sLastShader, tex);
    float4 shadowEffect = getShadow(tex, color);

    return max(normalOutline, max(sobelOutline, shadowEffect.r));

}

float4 outline(float2 rawTex : TEXCOORD0) : COLOR {
    float2 tex = distort(rawTex, distortionStrength, sDistortionMap);
    float3 pos = toView(tex, sDepthFrame);
    float fog = calculateFog(pos, fognearstart, fognearrange);

    float fadeStrength1 = getFadeStrength(tex);
    float thickness1 = calculateThickness(length(pos), maxDistance, outlineThickness);
    thickness1 = thickness1 * fadeStrength1;
    float depth = readDepth(tex, sDepthFrame);
    float3 outline = getOutline(tex, pos, thickness1, depth);

    //remove outline beyond fog
    outline = lerp(0, outline, saturate(fog + 0.3));

    float4 sceneColor = sampleSceneColor(rawTex, Time, distortionStrength * 1.1, sDistortionMap, timeOffsetMulti, sLastShader);
    float3 lineColor = min(sceneColor.rgb * lineDarkMulti, lineDarkMax);

    float3 color = lerp(sceneColor.rgb, lineColor, outline);
    return float4(color, sceneColor.a);
}

float4 getFadeStrengthTest(float2 Tex : TEXCOORD0) : COLOR {
    float fadeStrength = getFadeStrength(Tex);
    return float4(fadeStrength, fadeStrength, fadeStrength, 1);
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 79;> {
    pass a { PixelShader = compile ps_3_0 outline(); }
}
