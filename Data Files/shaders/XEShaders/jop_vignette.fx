
texture lastshader;
sampler s0 = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};

static const float Age = -3;
float4 vignette(float2 uv : TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, uv);
    float4 origColor = color;

    // Calc distance to center
    float2 dist = 0.5 - uv;

    // Vignette effect
    color.rgb *= (0.4 + -Age/100 - dot(dist, dist))  * 2.8;

    return lerp(origColor, color, 1);
}


technique T0 < string MGEinterface="MGE XE 0"; string category = "scene";  >
{
	pass p0 { PixelShader = compile ps_3_0 vignette(); }
}