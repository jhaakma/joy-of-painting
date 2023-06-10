// Black and White Shader
texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };
extern float threshold = 0.3;

float4 blackAndWhite(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, tex);

    // Convert the color to black and white
    float average = (color.r + color.g + color.b) / 3;

    // Define the thresholds for the limited band shades
    float darkGrayThreshold = (threshold + 0.0) / 2.0;
    float lightGrayThreshold = (threshold + 1.0) / 2.0;

    float dark1 = 0.01;
    float dark2 = 0.30;
    float dark3 = 0.50;

    // Quantize the average value to the limited band of shades
    if (average < darkGrayThreshold)
        color.rgb = float3(dark1, dark1, dark1); // Black
    else if (average < threshold)
        color.rgb = float3(dark2, dark2, dark2); // Light Gray
    else if (average < lightGrayThreshold)
        color.rgb = float3(dark3, dark3, dark3); // Dark Gray
    else
        color.rgb = float3(1, 1, 1); // White

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  >
{
	pass p0 { PixelShader = compile ps_3_0 blackAndWhite(); }
}