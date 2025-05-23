// Brightness, Contrast, and Saturation Shader

#include "jop_common.fx"

//Controlled vars
extern float brightness = 0;
extern float contrast = 1;
extern float saturation = 0;

//Automatic vars
extern float brightnessOffset = 0;
extern float contrastOffset = 0;
extern float saturationOffset = 0;

extern float hue = 0;

texture lastshader;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };




float4 adjust(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(sLastShader, tex);

    //BRIGHTNESS AND CONTRAST
    color.rgb += (brightness + brightnessOffset);
    color.rgb *= contrast + contrastOffset;

    //SATURATION
    color.rgb = applyVibrance(color.rgb, saturation + saturationOffset);

    //HUE
    float3 hsl = RGBToHSL(color.rgb);
    //hsl.x += hue;
    hsl.x = frac(hsl.x * (1 + hue));
    color.rgb = HSLToRGB(hsl);

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 36; >
{
	pass p0 { PixelShader = compile ps_3_0 adjust(); }
}
