// Black and White Shader
texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };
extern float threshold = 0.5;
float max_threshold = 3.0;

float4 blackAndWhite(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, tex);

    // Define the thresholds for the limited band shades
    float darkGrayThreshold = (threshold + 0.0) / max_threshold;
    float average = dot(color.rgb, float3(0.299, 0.587, 0.114));

    float black = 0.01;
    float white = 0.99;

    // Quantize the average value to the limited band of shades
    if (average < darkGrayThreshold)
        color.rgb = float3(black, black, black);
    else
        color.rgb = float3(white, white, white);

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 450;>
{
	pass p0 { PixelShader = compile ps_3_0 blackAndWhite(); }
}
