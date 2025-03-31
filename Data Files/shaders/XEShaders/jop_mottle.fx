#include "jop_common.fx"
extern float mottleStrength = 0.1;
extern float mottleSize = 2.0;
extern float speed = 0.3;

texture lastshader;
texture tex1 < string src="jop/splash_watercolor.tga"; >;

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sMottle = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };




// Step 3 & 4: Apply Mottling Effect and Sample Mottle Texture
float3 applyMottlingEffect(float2 uv, float3 baseColor)
{
    float3 newColor = baseColor; // Initialize new color
    //newColor = float3(0,0,0);

    float3 mottleColor = tex2D(sMottle, uv / mottleSize);
    newColor = overlay(newColor, mottleColor, mottleStrength);
    return newColor; // Blend base color with mottled color
}



float4 main(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    // apply mottling
    float2 uv1 = float2(tex.x + sin(Time * speed + 2) * 0.04, tex.y + cos(Time * speed + 2) * 0.04);
    float3 mottledColor = applyMottlingEffect(uv1, color);

    float2 uv2 = float2((1-tex.x) + sin(Time * speed + 2) * 0.09, (1-tex.y) + cos(Time * speed + 2) * 0.09);
    mottledColor = applyMottlingEffect(uv2, mottledColor);

    return float4(mottledColor, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 150;>
{
    pass a { PixelShader = compile ps_3_0 main(); }
}
