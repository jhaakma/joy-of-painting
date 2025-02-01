// Brightness, Contrast, and Saturation Shader
#include "jop_common.fx"

extern float distance = 250;
extern float maxDistance = 250-1;
extern float bgColor = 1.0;
texture lastshader;
texture lastpass;
texture depthframe;

sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };


float4 main(float2 tex: TEXCOORD0) : COLOR0
{
  float4 color = tex2D(sLastShader, tex);

  // Cull distant objects
  float depth = readDepth(tex, sDepthFrame);
  float distance_exp = pow(distance, 2);
  float maxDistance_exp = pow(maxDistance, 2);
  float transitionD = 100 + distance * 10;
  float4 fogColor = bgColor;
  color = lerp(color, fogColor, ( smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) )) );
  return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 60;>
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
