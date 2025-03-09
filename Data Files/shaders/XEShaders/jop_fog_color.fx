// Brightness, Contrast, and Saturation Shader

#include "jop_common.fx"

extern float distance = 250;
extern float maxDistance = 250-1;
extern float3 fogColor = {0.5, 0.5, 0.5};
extern float distortionStrength = 0.05;

texture lastshader;
texture lastpass;
texture depthframe;

texture tex1 < string src="jop/perlinNoise.tga"; >;
sampler2D sDistortionMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };


float4 main(float2 tex: TEXCOORD0) : COLOR0
{
  float2 distTex = distort(tex, distortionStrength, sDistortionMap);
  float3 color = tex2D(sLastShader, tex);

  // Cull distant objects
  float depth = readDepth(distTex, sDepthFrame);
  float distance_exp = pow(distance, 2);
  float maxDistance_exp = pow(maxDistance, 2);
  float transitionD = 100 + distance * 10;

  color = lerp(color, fogColor, ( smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) )) );

  return float4(color, 1);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 81;>
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
