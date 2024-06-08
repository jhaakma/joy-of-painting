// Brightness, Contrast, and Saturation Shader

extern float brightness = 0;
extern float contrast = 1;
extern float saturation = 1;
extern float distance = 250;
extern float maxDistance = 250-1;
extern float hueShift = 0;

texture lastshader;
texture lastpass;
texture depthframe;

sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler s1 = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float readDepth(float2 tex)
{
	float depth = pow(tex2D(s1, tex).r,1);
	return depth;
}


float4 brightness_contrast_saturation(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, tex);
    // Modify the brightness and contrast of the image
    color.rgb += brightness;
    color.rgb *= contrast;

    // Adjust the saturation of the image
    float average = (color.r + color.g + color.b) / 3;
    color.rgb = lerp(average, color.rgb, saturation);

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "scene"; int priorityAdjust = 5000; >
{
	pass p0 { PixelShader = compile ps_3_0 brightness_contrast_saturation(); }
}
