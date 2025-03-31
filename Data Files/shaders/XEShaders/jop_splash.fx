#include "jop_common.fx"

texture tex1 < string src="jop/oilOverlay.tga"; >;
texture lastshader;

extern float canvas_strength = 0.0;
extern float speed = 0.2;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sOverlayImage = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};


float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Sample the scroll texture
    float2 scrollUV = float2(Tex.x + sin(Time*speed) * 0.05, Tex.y + cos(Time*speed) * 0.05);
    float4 scrollTex = tex2D(sOverlayImage, scrollUV);
    // Sample the input image
    float4 image = tex2D(sImage, Tex);
    image.rgb = overlay(image.rgb, scrollTex.rgb, canvas_strength);
    return image;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  int priorityAdjust = 150; >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}