#define LineThickness 0.001
#define SensitivityUpper 10
#define SensitivityLower 10
#define Saturation 1.0
extern float Brightness = 0.2;

texture lastshader;
texture lastpass;
texture depthframe;
float2 rcpres;
sampler s0 = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s2 = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};

#define width rcpres.x
#define height rcpres.y

float4 brightness(float2 tex: TEXCOORD0) : COLOR0
{
  float4 color = tex2D(s0, tex);
  color.rgb += Brightness;
  return color;
}

float4 edge_detect(float2 tex : TEXCOORD0) : COLOR
{
	float dx =width/height * LineThickness;
	float dy =LineThickness;

	float4 c1 = tex2D(s2, tex + float2(-dx,-dy));
	float4 c2 = tex2D(s2, tex + float2(0,-dy));
	float4 c3 = tex2D(s2, tex + float2(-dx,dy));
	float4 c4 = tex2D(s2, tex + float2(-dx,0));
	float4 c5 = tex2D(s2, tex + float2(0,0));
	float4 c6 = tex2D(s2, tex + float2(dx,0));
	float4 c7 = tex2D(s2, tex + float2(dx,-dy));
	float4 c8 = tex2D(s2, tex + float2(0,dy));
	float4 c9 = tex2D(s2, tex + float2(dx,dy));

	float4 c0 = (-c1-c2-c3-c4+c6+c7+c8+c9);

       float4 average = (c1 + c2 + c3 + c4 + c6 +  c7 + c8 + c9) - (c5 * 6);
	float av = (average .r + average .g + average .b) / 3;

	c0 = 1-abs((c0.r+c0.g+c0.b)/av);
        float val = pow(saturate((c0.r + c0.g + c0.b) / 3), SensitivityUpper);
	val = 1 - pow(1 - val, SensitivityLower);

	float3 gray = float3(val, val, val);
	float3 blackWhite = saturate(gray * Saturation);
	return float4(blackWhite, 1.0);
}


technique T0 < string MGEinterface="MGE XE 0"; string category = "atmosphere"; >
{
	pass p0 { PixelShader = compile ps_3_0 brightness(); }
    pass p1 { PixelShader = compile ps_3_0 edge_detect(); }
}
