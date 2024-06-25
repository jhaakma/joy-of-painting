extern float hatchStrength = 4.0;
extern float hatchSize = 0.15;

#define PI 3.1415926535897932384626433832795

float3 eyepos, eyevec;
float2 rcpres;
float fov;
float waterlevel;

matrix mview;
matrix mproj;

texture lastshader;
texture lastpass;
texture depthframe;
texture tex1 < string src="jop/Hatch1.tga"; >;
texture tex2 < string src="jop/Hatch2.tga"; >;

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = wrap; addressv = wrap; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; };
sampler sHatch1 = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sHatch2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };

static const float2 invproj =  2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);
static const float xylength = sqrt(1 - eyevec.z * eyevec.z);
static const float sky = 1e6;

float readDepth(in float2 coord : TEXCOORD0)
{
	float posZ = tex2D(sDepthFrame, coord).x;
	return posZ;
}

float4 sample0(sampler2D s, float2 t)
{
    return tex2Dlod(s, float4(t, 0, 0));
}

float3 toView(float2 tex)
{
    float depth = sample0(sDepthFrame, tex).r;
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}



float getNormal(in float2 tex : TEXCOORD0)
{
    float3 pos = toView(tex);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;

    if(pos.z <= 0 || pos.z > sky || (water - waterlevel) < 0)
        return float4(0.5, 0.5, 1, 1);

    float3 left = pos - toView(tex + rcpres * float2(-1, 0));
    float3 right = toView(tex + rcpres * float2(1, 0)) - pos;
    float3 up = pos - toView(tex + rcpres * float2(0, -1));
    float3 down = toView(tex + rcpres * float2(0, 1)) - pos;

    float3 dx = length(left) < length(right) ? left : right;
    float3 dy = length(up) < length(down) ? up : down;

    float3 normal = normalize(cross(dy, dx));

    return normal;
}


float3 getSmoothedNormal(in float2 tex : TEXCOORD0)
{
    float3 originalNormal = getNormal(tex);
    float2 offsets[8] = {
        float2(-1, -1),
        float2(-1, 0),
        float2(-1, 1),
        float2(0, -1),
        float2(0, 1),
        float2(1, -1),
        float2(1, 0),
        float2(1, 1),
    };
    float3 sumNormals = originalNormal;
    for (int i = 0; i < 8; ++i)
    {
        float2 neighborTex = tex + rcpres * offsets[i];
        float3 neighborNormal = getNormal(neighborTex);
        sumNormals += neighborNormal;
    }
    float3 averagedNormal = sumNormals / 9.0; // Original normal + neighbors
    return normalize(averagedNormal);
}

/***********************************************************
*  Hatch shader
* The hatch texture is 6 levels of hatching encoded
* In the RGB of two images side by side
***********************************************************/


float3 Hatching(float2 _uv, half _intensity)
{

    float strength = saturate(_intensity * hatchStrength);


    //rotate uv by 45 degrees
    float2 uv = sin(PI/4) * _uv + cos(PI/4) * _uv;
    half3 hatch1 = tex2D(sHatch1, uv / hatchSize).rgb;
    half3 hatch0 = tex2D(sHatch2, uv / hatchSize).rgb;

    half3 overbright = max(0, strength - 1.0);

    half3 weightsA = saturate((strength * 6.0) + half3(-0, -1, -2));
    half3 weightsB = saturate((strength * 6.0) + half3(-3, -4, -5));

    weightsA.xy -= weightsA.yz;
    weightsA.z -= weightsB.x;
    weightsB.xy -= weightsB.yz;

    hatch0 = hatch0 * weightsA;
    hatch1 = hatch1 * weightsB;

    half3 hatching = overbright + hatch0.r +
    	hatch0.g + hatch0.b +
    	hatch1.r + hatch1.g +
    	hatch1.b;

    return hatching;
}


float2 rotateUvByNormal(float2 uv, float3 normal)
{
    // Step 1: Calculate rotation axis and angle
    float3 upVector = float3(0, 1, 0);
    float3 rotationAxis = cross(upVector, normal);
    float angle = acos(dot(normalize(upVector), normalize(normal)));

    // Step 2: Create rotation matrix
    float c = cos(angle);
    float s = sin(angle);
    float t = 1.0 - c;
    float x = rotationAxis.x, y = rotationAxis.y, z = rotationAxis.z;
    float3x3 rotationMatrix = float3x3(
        t*x*x + c,    t*x*y - s*z,  t*x*z + s*y,
        t*x*y + s*z,  t*y*y + c,    t*y*z - s*x,
        t*x*z - s*y,  t*y*z + s*x,  t*z*z + c
    );

    // Step 3: Apply rotation to the hatch pattern
    float2 rotatedHatchPosition = mul(rotationMatrix, uv);
    return rotatedHatchPosition;
}

float4 hatch(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    float3 normal = getSmoothedNormal(tex);

    // Adjust UV coordinates based on the normal
    float2 adjustedUV = tex;
    //Rotate the hatch texture according the normal
    adjustedUV = rotateUvByNormal(adjustedUV, normal);

    // Get luminosity
    float luminosity = dot(color, float3(0.299, 0.587, 0.114));

    // Use adjusted UV for hatching
    float3 hatching = Hatching(adjustedUV, luminosity);

    return float4(hatching, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 75;>
{
    pass a { PixelShader = compile ps_3_0 hatch(); }
}
