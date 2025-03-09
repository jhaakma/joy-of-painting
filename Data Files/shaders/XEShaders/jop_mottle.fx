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

    // Lighten based on luminosity of mottle color
    float2 randomUv = float2(uv.x + sin(Time * speed + 2) * 0.04, uv.y + cos(Time * speed + 2) * 0.04);

    float3 mottleColor;
    mottleColor = tex2D(sMottle, randomUv / mottleSize);
    float lum = getLuminosity(mottleColor);
    mottleColor = lerp(mottleColor, float3(0, 0, 0), lum);
    mottleColor = mottleColor * mottleStrength;

    newColor = newColor + mottleColor;
    return newColor; // Blend base color with mottled color
}



float4 main(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    // apply mottling
    float3 mottledColor = applyMottlingEffect(tex, color);

    return float4(mottledColor, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 150;>
{
    pass a { PixelShader = compile ps_3_0 main(); }
}
