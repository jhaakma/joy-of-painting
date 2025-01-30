//Distort vars
extern float timeOffsetMulti = 0.0;
extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion
extern float speed = 0.5;
extern float scale = 3;
extern float distance = 0.1;

extern float fogDistance = 0;
float time;

extern float hatchStrength = 4.0;
extern float hatchSize = 0.1;

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
texture tex4;
sampler sampNormals = sampler_state { texture = <tex1>; minfilter = anisotropic; magfilter = linear; mipfilter = linear; addressu = wrap; addressv = wrap; };

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


float2 distort(float2 Tex, float offset = 0) {

    float thisTime = time + offset;
    // Move around over time
    float2 uvR = float2(Tex.x + sin(thisTime * speed) * distance, Tex.y + cos(thisTime * speed) * distance) / scale;
    float2 uvG = float2(Tex.x + cos(thisTime * speed) * distance, Tex.y + sin(thisTime * speed) * distance) / scale * 1.1;
    float2 uvB = float2(Tex.x - sin(thisTime * speed) * distance, Tex.y - cos(thisTime * speed) * distance) / scale * 1.3;

    float4 normalMapR = tex2D(sNormalMap, uvR);
    float4 normalMapG = tex2D(sNormalMap, uvG);
    float4 normalMapB = tex2D(sNormalMap, uvB);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortionR = (normalMapR.rg * 2.0 - 1.0);
    float2 distortionG = (normalMapG.rg * 2.0 - 1.0);
    float2 distortionB = (normalMapB.rg * 2.0 - 1.0);

    // Combine the distortions from each channel
    float2 combinedDistortion = (distortionR + distortionG + distortionB) / 3.0;

    // Apply the combined distortion to the texture coordinates
    float2 distort = Tex + combinedDistortion * distortionStrength;

    return distort;
}


float3 toView(float2 tex)
{
    float depth = sample0(sDepthFrame, tex).r;
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

float3 toWorldWithDepth(float2 uv, float depth)
{
    // This version modifies your toWorld() to incorporate depth.
    // (Adjust signs, near/far plane logic, or matrix usage as needed.)
    // Some engines use [0..1] for depth; others might use different ranges.

    // Move uv from [0..1] into clip space [-1..1]
    float2 clip = float2(2.0 * uv.x - 1.0, 1.0 - 2.0 * uv.y);

    // Start with the camera's forward basis from your mview, etc.
    // We'll just show a pseudo-code version:
    float3 wpos = float3(mview[0][2], mview[1][2], mview[2][2]);

    // Scale factors from the projection
    float invProjX = 1.0 / mproj[0][0];  // typically FOV scale
    float invProjY = 1.0 / mproj[1][1];

    // "clip.x" is the [-1..1] x coordinate
    wpos += (clip.x * invProjX) * float3(mview[0][0], mview[1][0], mview[2][0]);
    wpos += (clip.y * -invProjY) * float3(mview[0][1], mview[1][1], mview[2][1]);

    // Adjust by 'depth' in a way consistent with your engine's depth range
    // Exactly how you factor in 'depth' depends on how your pipeline is set up.
    // E.g., you might do something like:
    wpos *= depth;  // or apply near/far plane logic as appropriate

    return wpos;
}

float3 getWorldSpaceNormal(float2 uv)
{

    // Sample depth from the depth buffer
    float depthC = sample0(sDepthFrame, uv).r;

    // Get the world‐space position at the center
    float3 center = toWorldWithDepth(uv, depthC);

    float3 pos = toView(uv);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;

    if(pos.z <= 0 || pos.z > sky || (water - waterlevel) < 0)
        return float3(0, 0, 1);

    // Offset in X
    float2 uvR = uv + float2(rcpres.x, 0);
    float2 uvL = uv - float2(rcpres.x, 0);

    float3 posR = toWorldWithDepth(uvR, sample0(sDepthFrame, uvR).r);
    float3 posL = toWorldWithDepth(uvL, sample0(sDepthFrame, uvL).r);

    // Offset in Y
    float2 uvD = uv + float2(0, rcpres.y);
    float2 uvU = uv - float2(0, rcpres.y);

    float3 posD = toWorldWithDepth(uvD, sample0(sDepthFrame, uvD).r);
    float3 posU = toWorldWithDepth(uvU, sample0(sDepthFrame, uvU).r);

    // Compute partial derivatives: one across X, one across Y
    float3 dX = posR - posL;
    float3 dY = posD - posU;

    // World‐space normal via cross product
    float3 N = normalize(cross(dX, dY));

    return N;
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
    float3 f = float3(0, 1, 0);
    float3 u = float3(0, 0, 1);

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
    float rotationAngle = PI/6;
    rotatedUV = float2(cos(rotationAngle)
        * rotatedUV.x - sin(rotationAngle)
        * rotatedUV.y, sin(rotationAngle)
        * rotatedUV.x + cos(rotationAngle)
        * rotatedUV.y);

    return rotatedUV;
}

float readDepth(float2 tex)
{
	float depth = pow(tex2D(sDepthFrame, tex).r,1);
	return depth;
}


float4 hatch(float2 tex : TEXCOORD0) : COLOR0
{
    float2 distortTex = distort(tex, 0.0);;
    float3 color = tex2D(sLastShader, tex).rgb;
    float3 normal = getWorldSpaceNormal(distortTex);

    float expDistance =  pow(fogDistance, 2);
    bool beyondFog = fogDistance < 250 && readDepth(distortTex) > expDistance;

    if ( beyondFog )
    {
        normal = float3(0,0,1);
    }

    normal = lerp(normal, float3(0,0,1), beyondFog);

    // Adjust UV coordinates based on the normal
    float2 adjustedUV = tex;
    //Rotate the hatch texture according the normal
    adjustedUV = rotateUvByNormal(adjustedUV, normal);

    // Get luminosity
    float luminosity = dot(color, float3(0.299, 0.587, 0.114));

    // beyond fog is white
    float depth = readDepth(distortTex);
    float distance_exp = pow(fogDistance, 2);
    float maxDistance_exp = pow(249, 2);
    float transitionD = 100 + fogDistance * 10;

    luminosity = lerp(luminosity, 1, smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) ));

    // Use adjusted UV for hatching
    float3 hatching = Hatching(adjustedUV, luminosity);

    return float4(hatching , 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 81;>
{
    pass a { PixelShader = compile ps_3_0 hatch(); }
}