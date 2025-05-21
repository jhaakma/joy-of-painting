#include "jop_common.fx"

extern float canvas_strength = 0.0;
extern float scroll_strength = 0.1;
extern float scale = 1.0;
extern float speed = 0.2;

texture lastshader;
texture tex1 < string src="jop/oilOverlay.tga"; >;
texture tex2 < string src="jop/oilOverlay2.tga"; >;
texture tex3 < string src="jop/perlinNoise.tga"; >;
texture tex4 < string src="jop/emptytexscroll.tga"; >;


sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sMottle = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sMottle2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sScroll = sampler_state { texture = <tex4>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler2D sDistortionMap = sampler_state { texture=<tex3>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};



// Step 3 & 4: Apply Mottling Effect and Sample Mottle Texture
float3 applyMottlingEffect(float2 uv, float3 baseColor, float3 mottleColor, float strength)
{
    float3 newColor = baseColor; // Initialize new color
    //newColor = float3(0,0,0);

    //convert to greyscale
    float grey = getLuminosity(mottleColor);
    //mottleColor = float3(grey, grey, grey);

    newColor = overlay(newColor, mottleColor, strength);
    return newColor; // Blend base color with mottled color
}



float4 main(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    // apply texture to dark areas
    float2 uv1 = float2(tex.x + sin(Time * speed + 2) * 0.04, tex.y + cos(Time * speed + 2) * 0.04);
    float strength1 = canvas_strength * (1 - getLuminosity(color));
    float2 distTex1 = distort(uv1, 0.05, sDistortionMap, 0);
    float3 mottleColor1 = tex2D(sMottle, distTex1 * scale);
    float3 result = applyMottlingEffect(uv1, color, mottleColor1, strength1);

    // apply texture to light areas
    float2 uv2 = float2((tex.x) + sin(Time * speed + 2) * 0.09, (tex.y) + cos(Time * speed + 2) * 0.09);
    float strength2 = canvas_strength * getLuminosity(color);
    float2 distTex2 = distort(uv2, 0.05, sDistortionMap, 20);
    float3 mottleColor2 = tex2D(sMottle2, distTex2 * scale);
    result = applyMottlingEffect(uv2, result, mottleColor2, strength2);

    // apply scroll texture to the whole image
    float2 scrollTex = distort(tex, 0.1, sScroll, 0);
    float3 scrollColor = tex2D(sScroll, tex * scale).rgb;
    scrollColor = grayscale(scrollColor);
    result = applyMottlingEffect(tex, result, scrollColor, scroll_strength);

    return float4(result, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 159;>
{
    pass a { PixelShader = compile ps_3_0 main(); }
}
