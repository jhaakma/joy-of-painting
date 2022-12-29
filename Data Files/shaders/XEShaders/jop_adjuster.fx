// Brightness, Contrast, and Saturation Shader

extern float brightness = 0;
extern float contrast = 1;
extern float saturation = 1;
extern float distance = 200;
extern float maxDistance = 500-1;
texture lastshader;
texture lastpass;
texture depthframe;

sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler s1 = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s2 = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};

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
  // Cull distant objects
  float depth = readDepth(tex);
  float distance_exp = pow(distance, 2);
  float maxDistance_exp = pow(maxDistance, 2);
  color = color * ( 1 - smoothstep(distance_exp, distance_exp + 500, depth ) * ( step(distance_exp, maxDistance_exp) ) );
  return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "scene";  >
{
	pass p0 { PixelShader = compile ps_3_0 brightness_contrast_saturation(); }
}
