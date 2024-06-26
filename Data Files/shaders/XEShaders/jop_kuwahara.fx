texture lastshader;

sampler s0 = sampler_state { texture = <lastshader>; magfilter = point; minfilter = point; };

float PI = 3.14159265359;
float2 rcpres;
extern float radius = 12;

struct Region
{
    float3 mean;
    float variance;
};


float gaussian(float sigma, float pos) {
    return (1.0f / sqrt(2.0f * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
}

Region calcRegion(float2 uv, int xStart, int xEnd, int yStart, int yEnd)
{
    Region r;
    float3 sum = 0.0;
    float3 squareSum = 0.0;
    float totalWeight = 0.0;

    int samples = 0;
    [loop]
    for (int x = xStart; x <= xEnd; x++)
    {
        [loop]
        for (int y = yStart; y <= yEnd; y++)
        {
            float within_kernel = step(length(float2(x, y)), radius);
            if (within_kernel == 1) {
                float2 offset = float2(rcpres.x * x, rcpres.y * y);
                float3 tex = tex2D(s0, uv + offset);

                float weight = gaussian(radius, length(float2(x, y)));
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
    int upper = (radius*2 - 1) / 2;
    int lower = -upper;

    int samples = (upper + 1) * (upper + 1);

    Region regionA = calcRegion(tex, -12, 0, -12, 0);
    Region regionB = calcRegion(tex, 0, 12, -12, 0);
    Region regionC = calcRegion(tex, -12, 0, 0, 12);
    Region regionD = calcRegion(tex, 0, 12, 0, 12);

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

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 68;   >
{
    pass { PixelShader = compile ps_3_0 paint(); }
}
