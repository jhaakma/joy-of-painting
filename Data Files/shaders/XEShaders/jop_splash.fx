texture tex1 < string src="jop/emptytexscroll.tga"; >;
texture lastshader;
float time;
extern float canvas_strength = 0.3;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sOverlayImage = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float3 overlay(float3 image, float3 canvas, float blendStrength) {

    //First greyscale the canvas so it doesn't affect image color
    float3 greyCanvas = canvas;
    float average = dot(greyCanvas.rgb, float3(0.299, 0.587, 0.114));
    greyCanvas.rgb = float3(average, average, average);

        // Multiply for painting < 0.5
    float3 multiplyVal = 2.0 * image * greyCanvas;

    // Screen for painting >= 0.5
    float3 screenVal = 1.0 - 2.0 * (1.0 - image) * (1.0 - greyCanvas);

    // step(0.5, image) is 0 if image < 0.5, 1 if image >= 0.5
    float3 result = lerp(multiplyVal, screenVal, step(0.5, greyCanvas));

    return lerp(image, result, blendStrength*0.25);
}


float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Sample the scroll texture
    float2 scrollUV = float2(Tex.x + sin(time) * 0.05, Tex.y + cos(time) * 0.05);
    float4 scrollTex = tex2D(sOverlayImage, scrollUV);

    // Sample the input image
    float4 image = tex2D(sImage, Tex);

    // Use the brightness to lighten or darken the image
    //float4 final = image + ((scrollTex - 0.5) * canvas_strength);
    //float4 final = float4(overlay(image.rgb, scrollTex.rgb, canvas_strength), 1.0);
    float brightness = max(max(image.r, image.g), image.b);
    float4 final = lerp(image, scrollTex, saturate(brightness * canvas_strength));

    return final;
}
technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  int priorityAdjust = 150; >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}