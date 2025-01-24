// Brightness, Contrast, and Saturation Shader

extern float distance = 250;
extern float maxDistance = 250-1;
extern float3 fogColor = {0.5, 0.5, 0.5};

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


float4 main(float2 tex: TEXCOORD0) : COLOR0
{
  float3 color = tex2D(s0, tex);

  // Cull distant objects
  float depth = readDepth(tex);
  float distance_exp = pow(distance, 2);
  float maxDistance_exp = pow(maxDistance, 2);
  float transitionD = 100 + distance * 10;

  color = lerp(color, fogColor, ( smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) )) );

  return float4(color, 1);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 60;>
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
