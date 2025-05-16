#include "jop_common.fx"
#include "jop_gaussian.fx"

texture lastshader;
texture lastpass;
texture depthframe;

sampler2D sLastShader = sampler_state {
    texture = <lastshader>;
    minfilter = linear; magfilter = linear; mipfilter = linear;
    addressu = clamp; addressv = clamp;
};

sampler2D sLastPass = sampler_state {
    texture = <lastpass>;
    minfilter = linear; magfilter = linear; mipfilter = linear;
    addressu = clamp; addressv = clamp;
};

sampler2D sDepthFrame = sampler_state {
    texture = <depthframe>;
    minfilter = point; magfilter = point;
    addressu = clamp; addressv = clamp;
};

// OUTPUT OF HORIZONTAL BLUR GOES HERE
texture texBlurH;
sampler2D sTexBlurH = sampler_state {
    texture = <texBlurH>;
    minfilter = linear; magfilter = linear; mipfilter = linear;
    addressu = clamp; addressv = clamp;
};

// Externs
extern float target_depth = 5000000.0; // Focus distance in eye-space (default 500 units)
extern float blur_strength = 0.0;  // Multiplier for blur radius
extern float focus_range = 1000.0;   // Width of the sharp zone in depth units



// First pass: Horizontal Gaussian blur
float4 dof_blur_h(float2 tex : TEXCOORD0) : COLOR0
{
    float adjusted_focus_range = focus_range * 1.5; // Adjusted focus range for depth calculation
    float depth = readDepth(tex, sDepthFrame);
    float blurAmount = saturate(abs(depth - target_depth) / adjusted_focus_range);
    float radius = blurAmount * blur_strength;

    float3 blurred = GaussianBlurH(tex, sLastShader, radius, rcpres);
    return float4(blurred, 1);
}

// Second pass: Vertical Gaussian blur
float4 dof_blur_v(float2 tex : TEXCOORD0) : COLOR0
{
    float adjusted_focus_range = focus_range * 1.5; // Adjusted focus range for depth calculation
    float depth = readDepth(tex, sDepthFrame);
    float blurAmount = saturate(abs(depth - target_depth) / adjusted_focus_range);
    float radius = blurAmount * blur_strength;

    float3 blurred = GaussianBlurV(tex, sLastPass, radius, rcpres);
    return float4(blurred, 1);
}

technique T_Horizontal < string MGEinterface="MGE XE 0"; string category="final"; int priorityAdjust = 67; >
{
    pass P0 { PixelShader = compile ps_3_0 dof_blur_h(); }
    pass P1 { PixelShader = compile ps_3_0 dof_blur_v(); }
}
