#include "jop_common.fx"

extern float hatchStrength = 0.2; //smaller value = lines are less prominent
//The aspect ratio of the canvas window
float hatchSize = 1.0; //smaller value = smaller lines


texture lastshader;
texture lastpass;
texture tex1 < string src="jop/charcoal.tga"; >;

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sHatch = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sLastpass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};


float4 main(float2 Tex : TEXCOORD0) : COLOR0 {
    float4 color = tex2D(sImage, Tex);

    // Sample the pencil texture
    float4 hatch = sampleCanvasAligned(Tex, sHatch, aspectRatio);
    // Apply the pencil effect
    float4 result = saturate((color+0.1) / (1-hatch));
    // Clamping the result to avoid overflow
    return lerp(color, result, hatchStrength);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 80; >
{
	pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}