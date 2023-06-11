// Black and White Shader
texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };
extern float threshold = 0.5;
extern float contrast = 1.0;
extern float brightness = 0.0;

float4 blackAndWhite(float2 tex: TEXCOORD0) : COLOR0
{
    float4 color = tex2D(s0, tex);
    color.rgb += (brightness +0.1);
    color.rgb *= (contrast + 1.5);


    // Convert the color to black and white
    float average = (color.r + color.g + color.b) / 3;

    // Define the thresholds for the limited band shades
    float darkGrayThreshold = (threshold + 0.0) / 2.0;
    float lightGrayThreshold = (threshold + 1.0) / 2.0;

    float black = 0.10;
    float darkGrey = 0.30;
    float lightGrey = 0.50;
    float white = 0.70;

    // Quantize the average value to the limited band of shades
    if (average < darkGrayThreshold)
        color.rgb = float3(black, black, black);
    else if (average < threshold)
        color.rgb = float3(darkGrey, darkGrey, darkGrey);
    else if (average < lightGrayThreshold)
        color.rgb = float3(lightGrey, lightGrey, lightGrey);
    else
        color.rgb = float3(white, white, white);

    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final";  >
{
	pass p0 { PixelShader = compile ps_3_0 blackAndWhite(); }
}