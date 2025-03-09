
// Greyscale Shader
texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };

float4 greyscale(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, tex);
    //Convert to greyscale
    float average = dot(color.rgb, float3(0.299, 0.587, 0.114));
    color.rgb = float3(average, average, average);

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 450;>
{
    pass p0 { PixelShader = compile ps_3_0 greyscale(); }
}
