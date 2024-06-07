texture tex1 < string src="jop/overlay_2k.tga"; >;
texture lastshader;
float time;
extern float canvas_strength = 0.8;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sOverlayImage = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Sample the input image and scroll texture
    float4 image = tex2D(sImage, Tex);
    float2 scrollUV = float2(Tex.x + sin(time) * 0.1, Tex.y + cos(time) * 0.1);
    float4 scrollTex = tex2D(sOverlayImage, scrollUV);

    // Calculate luminosity
    float lum = sqrt(dot(image.rgb * image.rgb, float3(0.29, 0.58, 0.114)));

    // Blend the image with the scroll texture based on luminosity

    float4 final = lerp(image, scrollTex, lum * canvas_strength);

    return final;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  int priorityAdjust = 1000; >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}