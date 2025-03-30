#include "jop_common.fx"

extern float sharpen_strength = 10;

texture lastshader;

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float4 main(float2 tex: TEXCOORD0) : COLOR0
{

    float4 color = tex2D(sLastShader, tex);

    color.rgb = sharpen3x3(tex, sharpen_strength, sLastShader).rgb;

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 50; >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
}