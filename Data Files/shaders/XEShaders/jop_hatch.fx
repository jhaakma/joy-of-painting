//Distort vars
extern float timeOffsetMulti = 0.0;
extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion
extern float speed = 0.5;
extern float scale = 1.5;
extern float distance = 0.1;
float time;

extern float hatchStrength = 4.0;
extern float hatchSize = 0.25;

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
texture tex3 < string src="jop/perlinNoise.tga"; >; // Your normal map texture

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = wrap; addressv = wrap; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; };
sampler sHatch1 = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sHatch2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sNormalMap = sampler_state { texture=<tex3>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

static const float2 invproj =  2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);
static const float xylength = sqrt(1 - eyevec.z * eyevec.z);
static const float sky = 1e6;


float4 sample0(sampler2D s, float2 t)
{
    return tex2Dlod(s, float4(t, 0, 0));
}

float2 distortedTex(float2 Tex, float timeOffset) {
        // Sample the input image and normal map
    float4 image = tex2D(sImage, Tex);
    //move around over time
    float thisTime = time + timeOffset;
    float2 uv = float2(Tex.x + sin(thisTime*speed) * distance, Tex.y + cos(thisTime*speed) * distance) / scale;

    float4 normalMap = tex2D(sNormalMap, uv);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortion = (normalMap.rg * 2.0 - 1.0) * distortionStrength;

    // Apply the distortion to the texture coordinates
    float2 distortedTex = Tex + distortion;

    return distortedTex;
}

float3 toView(float2 tex)
{
    float depth = sample0(sDepthFrame, tex).r;
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}



float3 getNormal(in float2 rawTex : TEXCOORD0)
{
    float2 tex = distortedTex(rawTex, 0.0);;

    float3 pos = toView(tex);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;

    if(pos.z <= 0 || pos.z > sky || (water - waterlevel) < 0)
        return float3(0.5, 0.5, 1);

    float depth = tex2Dlod(sDepthFrame, float4(tex, 0, 0)).x;

    float3 depthL = pos - toView(tex + float2(-rcpres.x, 0));
    float3 depthR = toView(tex + float2(rcpres.x, 0)) - pos;
    float3 depthU = pos - toView(tex + float2(0, -rcpres.y));
    float3 depthD = toView(tex + float2(0, rcpres.y)) - pos;

    float4 H;
    H.x = tex2Dlod(sDepthFrame, float4(tex - float2(rcpres.x, 0), 0, 0)).x;
    H.y = tex2Dlod(sDepthFrame, float4(tex + float2(rcpres.x, 0), 0, 0)).x;
    H.z = tex2Dlod(sDepthFrame, float4(tex - float2(2 * rcpres.x, 0), 0, 0)).x;
    H.w = tex2Dlod(sDepthFrame, float4(tex + float2(2 * rcpres.x, 0), 0, 0)).x;
    float2 he = abs(H.xy * H.zw * rcp(2 * H.zw - H.xy) - depth);
    float3 hDeriv;
    if (he.x > he.y)
        hDeriv = depthR;
    else
        hDeriv = depthL;

    float4 V;
    V.x = tex2Dlod(sDepthFrame, float4(tex - float2(0, rcpres.y), 0, 0)).x;
    V.y = tex2Dlod(sDepthFrame, float4(tex + float2(0, rcpres.y), 0, 0)).x;
    V.z = tex2Dlod(sDepthFrame, float4(tex - float2(0, 2 * rcpres.y), 0, 0)).x;
    V.w = tex2Dlod(sDepthFrame, float4(tex + float2(0, 2 * rcpres.y), 0, 0)).x;
    float2 ve = abs(V.xy * V.zw * rcp(2 * V.zw - V.xy) - depth);
    float3 vDeriv;
    if (ve.x > ve.y)
        vDeriv = depthU;
    else
        vDeriv = depthD;

    return cross(hDeriv, vDeriv).xyz;
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
    //Normal: r = right, u = up, f = forward
    float3 r = float3(1, 0, 0);
    float3 u = float3(0, 1, 0);
    float3 f = float3(0, 0, 1);

    //Calculate the rotation matrix
    float3x3 rotationMatrix = float3x3(r, u, f);

    // Rotate the normal
    normal = mul(normal, rotationMatrix);

    // Calculate the angle between the normal and the forward vector
    float angle = acos(dot(normal, float3(0, 0, 1)));

    // Calculate cos(angle) and sin(angle) simultaneously
    float cosAngle, sinAngle;
    sincos(angle, sinAngle, cosAngle);

    // Rotate the UV coordinates by the angle
    float2 rotatedUV = float2(cosAngle * uv.x - sinAngle * uv.y, sinAngle * uv.x + cosAngle * uv.y);
    // Rotate by a further 15 degrees
    rotatedUV = float2(cos(PI/6) * rotatedUV.x - sin(PI/6) * rotatedUV.y, sin(PI/6) * rotatedUV.x + cos(PI/6) * rotatedUV.y);

    return rotatedUV;
}


float4 hatch(float2 tex : TEXCOORD0) : COLOR0
{



    float3 color = tex2D(sLastShader, tex).rgb;
    float3 normal = getNormal(tex);

    // Adjust UV coordinates based on the normal
    float2 adjustedUV = tex;
    //Rotate the hatch texture according the normal
    adjustedUV = rotateUvByNormal(adjustedUV, normal);

    // Get luminosity
    float luminosity = dot(color, float3(0.299, 0.587, 0.114));

    // Use adjusted UV for hatching
    float3 hatching = Hatching(adjustedUV, luminosity);

    return float4(hatching , 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 81;>
{
    pass a { PixelShader = compile ps_3_0 hatch(); }
}
