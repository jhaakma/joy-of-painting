// Greyscale Shader
texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };

float4 greyscale(float2 tex: TEXCOORD0) : COLOR0
{
  float4 color = tex2D(s0, tex);

  // Convert the color to greyscale
  float average = (color.r + color.g + color.b) / 3;
  color.r = average;
  color.g = average;
  color.b = average;

  return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  >
{
	pass p0 { PixelShader = compile ps_3_0 greyscale(); }
}