#include "jop_common.fx"

extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion

texture tex1 < string src="jop/perlinNoise.tga"; >; // Your normal map texture
texture lastshader; // The texture you want to distort
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDistortionMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Apply the distortion to the texture coordinates
    float2 distTex = distort(Tex, distortionStrength, sDistortionMap);
    // Sample the image again with the distorted texture coordinates
    float4 final = tex2D(sImage, distTex);
    return final;
}


technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 65;  >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
}
