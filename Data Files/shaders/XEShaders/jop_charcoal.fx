
extern float brightness = 0.0;
extern float contrast = 1.0;

texture lastshader;

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};


float4 main(float2 Tex : TEXCOORD0) : COLOR0 {
    float3 color = tex2D(sImage, Tex).rgb;
    //Increase contrast
    color = color * contrast;
    //Increase brightness
    color = saturate(color + brightness);
    return float4(color, 1);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 80; >
{
	pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}
