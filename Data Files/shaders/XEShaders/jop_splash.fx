texture tex1 < string src="jop/emptytexscroll.tga"; >;
texture lastshader;
float time;
extern float canvas_strength = 0.8;
extern int blend_type = 1;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sOverlayImage = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

// float4 main(float2 Tex : TEXCOORD0) : COLOR0
// {
//     // Sample the input image and scroll texture
//     float4 image = tex2D(sImage, Tex);
//     float2 scrollUV = float2(Tex.x + sin(time) * 0.1, Tex.y + cos(time) * 0.1);
//     float4 scrollTex = tex2D(sOverlayImage, scrollUV);

//     // Calculate luminosity
//     float lum = sqrt(dot(image.rgb * image.rgb, float3(0.29, 0.58, 0.114)));

//     // Blend the image with the scroll texture based on luminosity
//     //float4

//     float4 final = image;

//     //Luminosity blending
//     final = lerp(final, scrollTex, lum * canvas_strength * (blend_type == 1));

//     //Overlay blending
//     final = lerp(final, final * (1.0 - scrollTex) + scrollTex * final, blend_type == 2);

//     //Soft light blending
//     final = lerp(final, (scrollTex > 0.5) ? (2.0 * final * scrollTex + final * final * (1.0 - 2.0 * (scrollTex - 0.5))) : (sqrt(final) * (2.0 * scrollTex - 1.0) + 2.0 * final * (1.0 - scrollTex)), blend_type == 3);

//     //Hard light blending
//     final = lerp(final, (scrollTex > 0.5) ? (1.0 - (1.0 - final) * (1.0 - scrollTex)) : (final * scrollTex), blend_type == 4);

//     //Vivid light blending
//     final = lerp(final, (scrollTex > 0.5) ? (1.0 - (1.0 - final) / (2.0 * (scrollTex - 0.5))) : (final / (1.0 - 2.0 * scrollTex)), blend_type == 5);

//     return final;
// }
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