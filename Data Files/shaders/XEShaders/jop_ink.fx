extern float contrast = 1.0;
extern float brightness = 0.0;

texture lastshader;
float2 rcpres;
sampler sLastShader = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

#define width rcpres.x
#define height rcpres.y

float4 main(float2 tex : TEXCOORD0) : COLOR
{
    //Reduce brightness and contrast
    float4 color = tex2D(sLastShader, tex);
    color.rgb += brightness;
    color.rgb = color.rgb * contrast;

    return color;
}


technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 70;>
{
    pass p1 { PixelShader = compile ps_3_0 main(); }
}
