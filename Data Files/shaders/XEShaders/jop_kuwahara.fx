texture lastshader;

sampler s0 = sampler_state { texture = <lastshader>; magfilter = point; minfilter = point; };

float2 rcpres;
extern float KernelSize = 15;

struct Region
{
    float3 mean;
    float variance;
};


Region calcRegion(int2 lower, int2 upper, int samples, float2 uv, int xStart, int xEnd, int yStart, int yEnd)
{
    Region r;
    float3 sum = 0.0;
    float3 squareSum = 0.0;

    for (int x = xStart; x <= xEnd; x++)
    {
        for (int y = yStart; y <= yEnd; y++)
        {
            float within_kernel = step(lower.x, x) * step(lower.y, y) * step(x, upper.x) * step(y, upper.y);
            if (within_kernel == 1) {
                float2 offset = float2(rcpres.x * x, rcpres.y * y);
                float3 tex = tex2D(s0, uv + offset);

                sum += tex;
                squareSum += tex * tex;
            }
        }
    }

    r.mean = sum / samples;
    float3 variance = abs((squareSum / samples) - (r.mean * r.mean));
    r.variance = length(variance);

    return r;
}


Region calcRegionA(int2 lower, int2 upper, int samples, float2 uv)
{
    return calcRegion(lower, upper, samples, uv, -20, 0, -20, 0);
}

Region calcRegionB(int2 lower, int2 upper, int samples, float2 uv)
{
    return calcRegion(lower, upper, samples, uv, 0, 20, -20, 0);
}

Region calcRegionC(int2 lower, int2 upper, int samples, float2 uv)
{
    return calcRegion(lower, upper, samples, uv, -20, 0, 0, 20);
}

Region calcRegionD(int2 lower, int2 upper, int samples, float2 uv)
{
    return calcRegion(lower, upper, samples, uv, 0, 20, 0, 20);
}


float4 paint(float2 tex : TEXCOORD0) : COLOR
{
    int upper = (KernelSize - 1) / 2;
    int lower = -upper;

    int samples = (upper + 1) * (upper + 1);

    Region regionA = calcRegionA(int2(lower, lower), int2(0, 0), samples, tex);
    Region regionB = calcRegionB(int2(0, lower), int2(upper, 0), samples, tex);
    Region regionC = calcRegionC(int2(lower, 0), int2(0, upper), samples, tex);
    Region regionD = calcRegionD(int2(0, 0), int2(upper, upper), samples, tex);

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

technique T0 < string MGEinterface = "MGE XE 0"; string category = "scene"; int priorityAdjust = 3000;   >
{
    pass { PixelShader = compile ps_3_0 paint(); }
}
