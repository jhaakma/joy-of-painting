
extern float brightness = 0;
extern float contrast = 1.8;
extern float saturation = 1;

texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };

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

technique T0 < string MGEinterface="MGE XE 0"; string category = "scene";  >
{
	pass p0 { PixelShader = compile ps_3_0 brightness_contrast_saturation(); }
}