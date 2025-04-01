#include "jop_common.fx"
#include "jop_gaussian.fx"

texture lastshader;
texture lastpass;
texture depthframe;

sampler sLastShader = sampler_state { texture = <lastshader>; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture = <lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

extern float radius = 1;
extern float blur_strength = 1.0;

struct Region
{
    float3 mean;
    float variance;
};

#define KERNEL_RADIUS 7


Region calcRegion(float2 uv, int xStart, int xEnd, int yStart, int yEnd)
{
    Region r;
    float3 sum = 0.0;
    float3 squareSum = 0.0;
    float totalWeight = 0.0;

    int samples = 0;


    float minRadius = max(1, KERNEL_RADIUS * 0.5);
    float maxRadius = KERNEL_RADIUS;
    float effectiveRadius =  min(KERNEL_RADIUS, maxRadius);


    float depth = readDepth(uv, sDepthFrame);
    depth = saturate(depth / 100000);
    effectiveRadius = lerp(KERNEL_RADIUS, minRadius, depth);

    [loop]
    for (int x = xStart; x <= xEnd; x++)
    {
        [loop]
        for (int y = yStart; y <= yEnd; y++)
        {
            float within_kernel = step(length(float2(x, y)), effectiveRadius);
            if (within_kernel == 1) {
                float2 offset = float2(rcpres.x * x * radius, rcpres.y * y * radius);
                float3 tex = tex2D(sLastShader, uv + offset);

                float weight = kernelRad7[x + KERNEL_RADIUS][y + KERNEL_RADIUS];
                sum += tex * weight;
                squareSum += tex * tex * weight;
                totalWeight += weight;
                samples++;
            }
        }
    }

    r.mean = sum / totalWeight;
    float3 variance = abs((squareSum / totalWeight) - (r.mean * r.mean));
    r.variance = length(variance);

    return r;
}


float4 paint(float2 tex : TEXCOORD0) : COLOR
{

    Region regionA = calcRegion(tex, -KERNEL_RADIUS, 0, -KERNEL_RADIUS, 0);
    Region regionB = calcRegion(tex, 0, KERNEL_RADIUS, -KERNEL_RADIUS, 0);
    Region regionC = calcRegion(tex, -KERNEL_RADIUS, 0, 0, KERNEL_RADIUS);
    Region regionD = calcRegion(tex, 0, KERNEL_RADIUS, 0, KERNEL_RADIUS);

    float3 col = regionA.mean;
    float minVar = regionA.variance;

    float testVal;

    testVal = step(regionB.variance, minVar);
    col = lerp(col, regionB.mean, testVal);
    minVar = lerp(minVar, regionB.variance, testVal);

    testVal = step(regionC.variance, minVar);
    col = lerp(col, regionC.mean, testVal);
    minVar = lerp(minVar, regionC.variance, testVal);

    testVal = step(regionD.variance, minVar);
    col = lerp(col, regionD.mean, testVal);

    return float4(col, 1.0);
}



float4 main_blurH(float2 tex : TEXCOORD0) : COLOR
{
    float2 texelSize = rcpres; // e.g. (1.0 / screenWidth, 1.0 / screenHeight)
    float3 blurredH = GaussianBlurH(tex, sLastPass, blur_strength, texelSize);
    return float4(blurredH, 1);
}

float4 main_blurV(float2 tex : TEXCOORD0) : COLOR
{
    // blur
    float2 texelSize = rcpres; // e.g. (1.0 / screenWidth, 1.0 / screenHeight)
    float3 blurredV = GaussianBlurV(tex, sLastPass, blur_strength, texelSize);
    return float4(blurredV, 1);
}


technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 68;   >
{
    pass { PixelShader = compile ps_3_0 paint(); }
    pass { PixelShader = compile ps_3_0 main_blurH(); }
    pass { PixelShader = compile ps_3_0 main_blurV(); }
}
