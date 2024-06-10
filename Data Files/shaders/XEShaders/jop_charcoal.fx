
extern float brightness = 0;
extern float contrast = 1.8;

float2 rcpres;

texture lastshader;
texture lastpass;
texture tex1 < string src="jop/pencil_tile.tga"; >;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sScrollTex = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sLastpass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};


float4 main(float2 Tex : TEXCOORD0) : COLOR0 {
    float4 color = tex2D(sImage, Tex);

    // Modify the brightness and contrast of the image
    color.rgb += brightness;
    color.rgb *= contrast;

    float2 adjustedTex = float2(Tex.x * rcpres.y / rcpres.x, Tex.y) * 2.0;
    float4 pencil = tex2D(sScrollTex, adjustedTex);

    // Color dodge effect approximation
    float4 result = color / (1.0 - pencil);

    // Clamping the result to avoid overflow
    result = clamp(result, 0.0, 1.0);

    return result;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "scene"; int priorityAdjust = 100; >
{
	pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}
