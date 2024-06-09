texture tex1 < string src="jop/emptytexscroll.tga"; >;
texture lastshader;
float time;
extern float canvas_strength = 0.7;
extern int blend_type = 1;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sOverlayImage = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Sample the scroll texture
    float2 scrollUV = float2(Tex.x + sin(time) * 0.1, Tex.y + cos(time) * 0.1);
    float4 scrollTex = tex2D(sOverlayImage, scrollUV);

    // Calculate the brightness of the scroll texture
    float brightness = dot(scrollTex.rgb, float3(0.299, 0.587, 0.114));

    // Sample the input image
    float4 image = tex2D(sImage, Tex);

    // Use the brightness to lighten or darken the image
    float4 final = image * (1.0 + (brightness - 0.5) * canvas_strength);

    return final;
}
technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  int priorityAdjust = 1000; >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}