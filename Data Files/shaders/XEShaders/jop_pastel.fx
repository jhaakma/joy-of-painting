#include "jop_gaussian.fx"
#include "jop_common.fx"

extern float canvas_strength = 0.3;
extern float canvas_strength2 = 0.2;
extern float canvas_scale = 1.0;
extern float grain_strength = 1.5;
extern float grain_scale = 1.0;
extern float lut_strength = 0.6;
extern float blur_strength = 1.5;
extern float sharpen_strength = 0;
extern float gamma = 1.5;
extern float vibrance = 0;
extern float3 overlay_range = 1.0;

texture tex1 < string src="jop/luts/pastel.tga"; >;
texture tex2 < string src="jop/pastelOverlay.tga"; >;
texture tex3 < string src="jop/pastelOverlay2.tga"; >;
texture tex4 < string src="jop/grain.tga"; >;
texture tex5 < string src="jop/perlinNoise.tga"; >;
texture lastshader;
texture lastpass;

sampler sLastShader = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLutPastel = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sOverlay = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sOverlay2 = sampler_state { texture = <tex3>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sGrain = sampler_state { texture = <tex4>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler2D sDistortionMap = sampler_state { texture=<tex5>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float3 lut( float3 colorIN, sampler2D LutSampler )
{
    float2 CLut_pSize = float2(0.00390625, 0.0625);// 1 / float2(256, 16);
    float4 CLut_UV;
    colorIN    = saturate(colorIN) * 15.0;
    CLut_UV.w  = floor(colorIN.b);
    CLut_UV.xy = (colorIN.rg + 0.5) * CLut_pSize;
    CLut_UV.x += CLut_UV.w * CLut_pSize.y;
    CLut_UV.z  = CLut_UV.x + CLut_pSize.y;
    return lerp( tex2Dlod(LutSampler, CLut_UV.xyzz).rgb, tex2Dlod(LutSampler, CLut_UV.zyzz).rgb, colorIN.b - CLut_UV.w);
}


float3 applyGamma(float3 color) {
    // gamma < 1 => brightens midtones, gamma > 1 => darkens midtones
    float3 newColor = pow(color, 1.0 / gamma);
    return newColor;
}



// Our updated pastelOverlay using an overlay blend mode
float3 doOverlay(
    float3 baseColor,
    float2 uv,
    float scale,
    float strength,
    sampler2D overlaySampler
)
{
    // Sample the grayscale overlay texture (assuming R=G=B)
    float coverage = tex2D(overlaySampler, uv * scale).r;

    return overlay(baseColor, coverage, strength);
}


float4 main_blurH(float2 tex : TEXCOORD0) : COLOR
{
    float2 texelSize = rcpres; // e.g. (1.0 / screenWidth, 1.0 / screenHeight)
    float3 blurredH = GaussianBlurH(tex, sLastShader, blur_strength, texelSize);
    return float4(blurredH, 1);
}

float4 main_blurV(float2 tex : TEXCOORD0) : COLOR
{
    // blur
    float2 texelSize = rcpres; // e.g. (1.0 / screenWidth, 1.0 / screenHeight)
    float3 blurredV = GaussianBlurV(tex, sLastPass, blur_strength, texelSize);
    return float4(blurredV, 1);
}


float4 main_pastel(float2 tex : TEXCOORD0) : COLOR
{
    float4 blurred = tex2D(sLastPass, tex);

    float4 sharpenedColor = sharpen3x3(tex, sharpen_strength, sLastShader);

    sharpenedColor.rgb = lerp(sharpenedColor.rgb, blurred.rgb, 0.5); // Blend with the blurred color

    // apply the selected LUT
    sharpenedColor.rgb = lerp(sharpenedColor.rgb, lut(sharpenedColor.rgb, sLutPastel), lut_strength);

    // apply gamma correction
    sharpenedColor.rgb = applyGamma(sharpenedColor.rgb);

    // apply vibrance
    sharpenedColor.rgb = applyVibrance(sharpenedColor.rgb, vibrance);

    return sharpenedColor;
}

float getBrightness(float3 color) {
    return max(max(color.r, color.g), color.b);
}

float4 main_overlay(float2 tex : TEXCOORD0) : COLOR
{
    float4 image = tex2D(sLastPass, tex);

    // apply the over on bright areas
    float2 uv1 = float2(tex.x + sin(Time * 0.2 + 2) * 0.04, tex.y + cos(Time * 0.2 + 2) * 0.04);
    float strength = canvas_strength *  saturate(0.3 + (getBrightness(image.rgb)));
    float2 distTex = distort(uv1, 0.1, sDistortionMap, 0);
    image.rgb = doOverlay(image.rgb, distTex, canvas_scale, strength, sOverlay);
    // apply the overlay on dark areas
    float2 uv2 = float2((tex.x) + sin(Time * 0.2 + 2) * 0.09, (tex.y) + cos(Time * 0.2 + 2) * 0.09);
    strength = canvas_strength2 * (1 - getBrightness(image.rgb));
    distTex = distort(uv2, 0.1, sDistortionMap, 20);
    image.rgb = doOverlay(image.rgb, distTex, grain_scale, strength, sOverlay2);

    // apply grain across the image
    image.rgb = overlay(image.rgb, tex2D(sGrain, tex).rgb, grain_strength * 0.1);


    return image;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 100; >
{
    pass p0 { PixelShader = compile ps_3_0 main_blurH(); }
    pass p1 { PixelShader = compile ps_3_0 main_blurV(); }
    pass p2 { PixelShader = compile ps_3_0 main_pastel(); }
    pass p4 { PixelShader = compile ps_3_0 main_overlay(); }
}