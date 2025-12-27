#include "jop_common.fx"

extern float vibrance = 1.0;
extern float threshold = 0.04;
extern float temperatureShiftStrength = 0.5;
extern float3 warmColor = float3(1.0, 0.9, 0.7);  // Warm yellow-orange tint
extern float3 coolColor = float3(0.7, 0.8, 1.0);  // Cool blue tint


texture lastshader;
texture depthframe;
texture lastpass;


sampler sLastShader = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDepthFrame = sampler_state { texture=<depthframe>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};


// Apply color temperature shifts based on luminosity
// Warm highlights, cool shadows - mimics oil painting behavior
float3 applyColorTemperature(float3 color, float strength)
{
    // Calculate luminosity
    float lum = dot(color, float3(0.299, 0.587, 0.114));

    // Create a curve that's smooth in the midtones
    // 0.0 = shadows (cool), 0.5 = midtones (neutral), 1.0 = highlights (warm)
    float temperatureCurve = smoothstep(0.0, 1.0, lum);

    // Blend between cool and warm based on luminosity
    float3 temperatureTint = lerp(coolColor, warmColor, temperatureCurve);

    // Apply the temperature shift
    // Use overlay-style blending to preserve the original color structure
    float3 result = color * temperatureTint;

    // Blend between original and temperature-shifted color
    return lerp(color, result, strength);
}


float4 edgedetecting( float2 tex : TEXCOORD0  ) : COLOR0
{

    float depth = readDepth(tex, sDepthFrame);
    float3 pos2 = getPosition(tex, depth);

    float3 left2 = pos2 - getPosition(tex + rcpres.xy * float2(-1, 0), readDepth(tex + rcpres.xy * float2(-1, 0), sDepthFrame));
    float3 right2 = getPosition(tex + rcpres.xy * float2(1, 0), readDepth(tex + rcpres.xy * float2(1, 0), sDepthFrame)) - pos2;
    float3 up2 = pos2 - getPosition(tex + rcpres.xy * float2(0, -1), readDepth(tex + rcpres.xy * float2(0, -1), sDepthFrame));
    float3 down2 = getPosition(tex + rcpres.xy * float2(0, 1), readDepth(tex + rcpres.xy * float2(0, 1), sDepthFrame)) - pos2;

    float3 dx2 = length(left2) < length(right2) ? left2 : right2;
    float3 dy2 = length(up2) < length(down2) ? up2 : down2;

    float3 norm = normalize(cross(dx2,dy2));
    norm.z *= -1;


    const int NUM = 9;
    const float2 c[NUM] =
    {
        float2(-0.0078125, 0.0078125),
        float2( 0.00 ,     0.0078125),
        float2( 0.0078125, 0.0078125),
        float2(-0.0078125, 0.00 ),
        float2( 0.0,       0.0),
        float2( 0.0078125, 0.007 ),
        float2(-0.0078125,-0.0078125),
        float2( 0.00 ,    -0.0078125),
        float2( 0.0078125,-0.0078125),
    };

    int i;
    float3 col[NUM];
    for (i=0; i < NUM; i++)
    {
        col[i] = tex2D(sLastShader, tex.xy + 0.2*c[i]);
    }

    float3 rgb2lum = float3(0.30, 0.59, 0.11);
    float lum[NUM];
    for (i = 0; i < NUM; i++)
    {
        lum[i] = dot(col[i].xyz, rgb2lum);
    }
    float x = lum[2]+  lum[8]+2*lum[5]-lum[0]-2*lum[3]-lum[6];
    float y = lum[6]+2*lum[7]+  lum[8]-lum[0]-2*lum[1]-lum[2];
    float edge =(x*x + y*y < threshold)? 1.0:0.0;


    return float4(norm.xyz,edge);

}



float4 splashblend( float2 Tex : TEXCOORD0 ) : COLOR0
{
    float4 image = tex2D(sLastShader,Tex);

    float lum = sqrt(dot(image.rgb * image.rgb, float3(0.29, 0.58, 0.114)));

    float3 edges = tex2D(sLastPass,Tex + float2(0.0, 0.0)).a/2;

    edges += tex2D(sLastPass,Tex + float2( 0.5, 0.5) * (rcpres.y)).a/8;
    edges += tex2D(sLastPass,Tex + float2( -0.5, 0.5) * (rcpres.y)).a/8;
    edges += tex2D(sLastPass,Tex + float2( 0.5, -0.5) * (rcpres.y)).a/8;
    edges += tex2D(sLastPass,Tex + float2( -0.5, -0.5) * (rcpres.y)).a/8;
    // edges more prominant in brighter areas
    edges *= smoothstep(0.0, 1.0, lum);


    float3 final = image.rgb * edges.rgb * edges.rgb;

    final = 1.0 - (1.0 - final) * (1.0 - image.rgb);

    //Increase saturation
    final.rgb = applyVibrance(final.rgb, vibrance);

    // Apply color temperature shifts (warm highlights, cool shadows)
    final.rgb = applyColorTemperature(final.rgb, temperatureShiftStrength);

    return float4(final.rgb,1);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 70;  >
{
    pass p0 { PixelShader = compile ps_3_0 edgedetecting(); }
    pass p3 { PixelShader = compile ps_3_0 splashblend(); }
}