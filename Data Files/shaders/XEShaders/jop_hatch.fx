#include "jop_common.fx"

//Distort vars
extern float timeOffsetMulti = 0.0;
extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion

extern float fogDistance = 100000;

extern float hatchStrength = 4.0;
extern float hatchSize = 0.1;

texture lastshader;
texture lastpass;
texture depthframe;
texture tex1 < string src="jop/Hatch1.tga"; >;
texture tex2 < string src="jop/Hatch2.tga"; >;
texture tex3 < string src="jop/perlinNoise.tga"; >; // Your normal map texture
texture tex4;
sampler sampNormals = sampler_state { texture = <tex1>; minfilter = anisotropic; magfilter = linear; mipfilter = linear; addressu = wrap; addressv = wrap; };

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = wrap; addressv = wrap; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; };
sampler sHatch1 = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };
sampler sHatch2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDistortionMap = sampler_state { texture=<tex3>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};


/***********************************************************
*  Hatch shader
* The hatch texture is 6 levels of hatching encoded
* In the RGB of two images side by side
***********************************************************/

float3 Hatching(float2 _uv, half _intensity)
{

    float strength = saturate(_intensity * hatchStrength);
    float2 uv = _uv * 1.2;
    half3 hatch1 = tex2D(sHatch1, uv / hatchSize).rgb;
    half3 hatch2 = tex2D(sHatch2, uv / hatchSize).rgb;

    half3 overbright = max(0, strength - 1.0);

    half3 weightsA = saturate((strength * 6.0) + half3(-0, -1, -2));
    half3 weightsB = saturate((strength * 6.0) + half3(-3, -4, -5));

    weightsA.xy -= weightsA.yz;
    weightsA.z -= weightsB.x;
    weightsB.xy -= weightsB.yz;

    hatch2 = hatch2 * weightsA;
    hatch1 = hatch1 * weightsB;

    half3 hatching = overbright + hatch2.r +
    	hatch2.g + hatch2.b +
    	hatch1.r + hatch1.g +
    	hatch1.b;
    return hatching;
}




float4 hatch(float2 tex : TEXCOORD0) : COLOR0
{
    float2 distortTex = distort(tex, distortionStrength, sDistortionMap);
    float3 color = tex2D(sLastShader, tex).rgb;
    float3 normal = getWorldSpaceNormal(distortTex, sDepthFrame);
    float depth = readDepth(distortTex, sDepthFrame);

    float expDistance =  pow(fogDistance, 2);
    bool beyondFog = depth > expDistance;

    if ( beyondFog )
    {
        normal = float3(0,0,1);
    }

    normal = lerp(normal, float3(0,0,1), beyondFog);

    // Adjust UV coordinates based on the normal
    float2 adjustedUV = tex;
    //Rotate the hatch texture according the normal
    adjustedUV = rotateUvByNormal(adjustedUV, normal, -PI/4);

    // Get luminosity
    float luminosity = dot(color, float3(0.299, 0.587, 0.114));

    // Use adjusted UV for hatching
    float3 hatching = Hatching(adjustedUV, luminosity);


    //Beyond fog is empty
    hatching = lerp(hatching, float3(1,1,1), beyondFog * (fogDistance < 250));


    return float4(hatching , 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 81;>
{
    pass a { PixelShader = compile ps_3_0 hatch(); }
}