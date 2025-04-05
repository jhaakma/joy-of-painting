#include "jop_common.fx"
extern float canvas_strength = 0.3;
extern float scale = 1.0;
extern float speed = 0.3;

texture lastshader;
texture tex1 < string src="jop/splash_watercolor.tga"; >;
texture tex2 < string src="jop/splash_watercolor_2.tga"; >;
texture tex3 < string src="jop/perlinNoise.tga"; >;


sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sMottle = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sMottle2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler2D sDistortionMap = sampler_state { texture=<tex3>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};



// Step 3 & 4: Apply Mottling Effect and Sample Mottle Texture
float3 applyMottlingEffect(float2 uv, float3 baseColor, float3 mottleColor, float strength)
{
    float3 newColor = baseColor; // Initialize new color
    //newColor = float3(0,0,0);
    newColor = overlay(newColor, mottleColor, strength);
    return newColor; // Blend base color with mottled color
}


float getBrightness(float3 color) {
    return max(max(color.r, color.g), color.b);
}


float4 main(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    // apply mottling
    float2 uv1 = float2(tex.x + sin(Time * speed + 2) * 0.04, tex.y + cos(Time * speed + 2) * 0.04);
    float strength1 = canvas_strength * (1 - getBrightness(color));
    float2 distTex1 = distort(uv1, 0.05, sDistortionMap, 0);
    float3 mottleColor1 = tex2D(sMottle, distTex1 / scale);
    float3 result = applyMottlingEffect(uv1, color, mottleColor1, strength1);

    float2 uv2 = float2((tex.x) + sin(Time * speed + 2) * 0.09, (tex.y) + cos(Time * speed + 2) * 0.09);
    float strength2 = canvas_strength * getBrightness(color);
    float2 distTex2 = distort(uv2, 0.1, sDistortionMap, 20);
    float3 mottleColor2 = tex2D(sMottle2, distTex2 / scale);
    result = applyMottlingEffect(uv2, result, mottleColor2, strength2);

    return float4(result, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 159;>
{
    pass a { PixelShader = compile ps_3_0 main(); }
}
