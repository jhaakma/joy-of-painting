// Number of luminosity levels to quantize into
extern int luminosityLevels = 16;

texture lastshader;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };

float4 main(float2 uv : TEXCOORD) : SV_Target {
    // Sample the texture color
    float4 texColor = tex2D(sLastShader, uv);
    // Calculate the original luminosity
    float luminosity = dot(texColor.rgb, float3(0.299, 0.587, 0.114));
    // Quantize luminosity into a fixed number of levels
    float offset = 1.0 / (2.0 * luminosityLevels);
    float quantizedLuminosity = floor(luminosity * luminosityLevels) / (luminosityLevels-1) - offset;

    // Adjust the color's brightness to match the quantized luminosity
    // Keeping the color's hue and saturation unchanged
    float3 adjustedColor = texColor.rgb * (quantizedLuminosity / luminosity);

    // Return the dynamically adjusted color with the original alpha
    return float4(adjustedColor, texColor.a);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 40; >
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
