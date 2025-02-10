#include "jop_common.fx"

// Number of luminosity levels to quantize into
extern int luminosityLevels = 12;
extern int hueLevels = 20;

texture lastshader;
texture depthframe;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float4 main(float2 uv : TEXCOORD) : SV_Target {

    float depth = saturate(readDepth(uv, sDepthFrame) / 100000);
    float maxLumLevels = max(luminosityLevels, luminosityLevels);
    float effectiveLumLevels = lerp(luminosityLevels, maxLumLevels, depth);

    float maxHueLevels = max(50, hueLevels);
    float effectiveHueLevels = lerp(hueLevels, maxHueLevels, depth);

    // Sample the texture color
    float4 texColor = tex2D(sLastShader, uv);

    // Convert RGB to HSL
    float3 hsl = RGBToHSL(texColor.rgb);

    // Quantize luminosity
    float luminosity = hsl.z;
    float offset = 1.0 / (2.0 * effectiveLumLevels);
    float quantizedLuminosity = lerp(luminosity, ceil(luminosity * effectiveLumLevels) / (effectiveLumLevels-1) - offset, luminosityLevels>0);
    // Quantize hue
    float hue = hsl.x;
    float quantizedHue = lerp(hue, ceil(hsl.x * effectiveHueLevels) / effectiveHueLevels, hueLevels>0);

    // Convert back to RGB
    hsl.z = quantizedLuminosity;
    hsl.x = quantizedHue;
    // Adjust the color's brightness to match the quantized luminosity
    // Keeping the color's hue and saturation unchanged
    float3 adjustedColor = HSLToRGB(hsl);

    // Return the dynamically adjusted color with the original alpha
    return float4(adjustedColor, texColor.a);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 158; >
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
