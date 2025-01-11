// Number of luminosity levels to quantize into
extern int luminosityLevels = 12;
extern int hueLevels = 20;

texture lastshader;
texture depthframe;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float3 RGBToHSL(float3 color)
{
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value

    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0)       //This is a gray, no chroma...
    {
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
    }
    else                                    //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (fmax + fmin); // Saturation
        else
            hsl.y = delta / (2.0 - fmax - fmin); // Saturation

        float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

        if (color.r == fmax )
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }

    return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

float3 HSLToRGB(float3 hsl)
{
    float3 rgb;

    if (hsl.y == 0.0)
        rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
    else
    {
        float f2;

        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

        float f1 = 2.0 * hsl.z - f2;

        rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = HueToRGB(f1, f2, hsl.x);
        rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
    }

    return rgb;
}

float readDepth(float2 tex)
{
	float depth = pow(tex2D(sDepthFrame, tex).r,1);
	return depth;
}



float4 main(float2 uv : TEXCOORD) : SV_Target {

    float depth = saturate(readDepth(uv) / 100000);
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
    float quantizedLuminosity = floor(luminosity * effectiveLumLevels) / (effectiveLumLevels-1) - offset;

    // Quantize hue
    float hue = hsl.x;
    float quantizedHue = floor(hsl.x * effectiveHueLevels) / effectiveHueLevels;

    // Convert back to RGB
    hsl.z = quantizedLuminosity;
    hsl.x = quantizedHue;
    // Adjust the color's brightness to match the quantized luminosity
    // Keeping the color's hue and saturation unchanged
    float3 adjustedColor = HSLToRGB(hsl);

    // Return the dynamically adjusted color with the original alpha
    return float4(adjustedColor, texColor.a);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 58; >
{
	pass p0 { PixelShader = compile ps_3_0 main(); }
}
