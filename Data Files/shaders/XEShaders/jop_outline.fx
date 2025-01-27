extern float maxDistance = 62000;
extern float outlineThickness = 2.0;
extern float lineTest = 5;
extern float lineDarkMulti = 0.8;
extern float lineDarkMax = 0.1;

extern float timeOffsetMulti = 0.0;
extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion
extern float speed = 0.5;
extern float scale = 3;
extern float distance = 0.1;
float time;

texture lastshader;
texture depthframe;
texture lastpass;
texture tex1 < string src="jop/perlinNoise.tga"; >; // Your normal map texture

sampler s0 = sampler_state
{
    texture = <lastshader>;
    addressu = clamp;
    addressv = clamp;
    magfilter = point;
    minfilter = point;
};
sampler s1 = sampler_state
{
    texture = <depthframe>;
    addressu = clamp;
    addressv = clamp;
    magfilter = point;
    minfilter = point;
};
sampler s2 = sampler_state
{
    texture = <lastpass>;
    addressu = clamp;
    addressv = clamp;
    magfilter = point;
    minfilter = point;
};

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sNormalMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = wrap; addressv = wrap; magfilter = point; minfilter = point; };


float3 eyevec, eyepos;
float waterlevel;
float2 rcpres;
float fogstart, fogrange, fognearrange, fognearstart;
float3 fognearcol;
matrix mproj;
float fov;
static float fogoffset = saturate(-fogstart / (fogrange - fogstart));

static const float2 invproj = 2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);


float OutlineDepthMultiplier = 1.0;
float OutlineDepthBias = 1.0;

float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot = float2(1.0, 1 / 255.0);
    return dot(enc, kDecodeDot);
}

float3 DecodeViewNormalStereo(float4 enc4)
{
    float kScale = 1.7777;
    float3 nn = enc4.xyz * float3(2 * kScale, 2 * kScale, 0) + float3(-kScale, -kScale, 1);
    float g = 2.0 / dot(nn.xyz, nn.xyz);
    float3 n;
    n.xy = g * nn.xy;
    n.z = g - 1;
    return n;
}

void DecodeDepthNormal(float4 enc, out float depth, out float3 normal)
{
    depth = DecodeFloatRG(enc.zw);
    normal = DecodeViewNormalStereo(enc);
}

float3 RGBtoHSL(float3 color)
{
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

    float fmin = min(min(color.r, color.g), color.b); // Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b); // Max. value of RGB
    float delta = fmax - fmin;                        // Delta RGB value

    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0) // This is a gray, no chroma...
    {
        hsl.x = 0.0; // Hue
        hsl.y = 0.0; // Saturation
    }
    else // Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (fmax + fmin); // Saturation
        else
            hsl.y = delta / (2.0 - fmax - fmin); // Saturation

        float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

        if (color.r == fmax)
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }

    return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

float3 HSLtoRGB(float3 hsl)
{
    float3 rgb;

    if (hsl.y == 0.0)
        rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
    else
    {
        float f2;

        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

        float f1 = 2.0 * hsl.z - f2;

        rgb.r = HueToRGB(f1, f2, hsl.x + (1.0 / 3.0));
        rgb.g = HueToRGB(f1, f2, hsl.x);
        rgb.b = HueToRGB(f1, f2, hsl.x - (1.0 / 3.0));
    }

    return rgb;
}

float4 sample0(sampler2D s, float2 t)
{
    return tex2Dlod(s, float4(t, 0, 0));
}

float3 toView(float2 tex)
{
    float depth = sample0(s1, tex).r;
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

float LinearEyeDepth(float z)
{
    float c = mproj._33;
    float e = mproj._43;
    float near = -e / c;
    float far = -((c * near) / (1 - c));
    float eyeDepth = far * near / ((near - far) * z + far);
    return (z);
}

float SobelDepth(float ldc, float ldl, float ldr, float ldu, float ldd)
{
    return (ldl - ldc) +
           (ldr - ldc) +
           (ldu - ldc) +
           (ldd - ldc);
}



float SobelSampleDepth(sampler s, float2 uv, float3 offset)
{
    float pixelCenter = LinearEyeDepth(sample0(s, uv).r);
    float pixelLeft = LinearEyeDepth(sample0(s, uv - offset.xz).r);
    float pixelRight = LinearEyeDepth(sample0(s, uv + offset.xz).r);
    float pixelUp = LinearEyeDepth(sample0(s, uv + offset.zy).r);
    float pixelDown = LinearEyeDepth(sample0(s, uv - offset.zy).r);

    return SobelDepth(pixelCenter, pixelLeft, pixelRight, pixelUp, pixelDown);
}

float readDepth(in float2 coord : TEXCOORD0)
{
	float posZ = tex2D(sDepthFrame, coord).x;
	return posZ;
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

static const float xylength = sqrt(1 - eyevec.z * eyevec.z);
float4 outline(float2 rawTex : TEXCOORD0) : COLOR
{
    float2 tex = distortedTex(rawTex, 0);

    float3 pos = toView(tex);
    float dist = length(pos);
    float fog = saturate((fognearrange - dist) / (fognearrange - fognearstart));

    //Thickness decreases by distance
    float clamped_dist = saturate(dist / maxDistance);
    float thickness =  outlineThickness + outlineThickness * (1.0 - clamped_dist);


    float3 offset = float3(rcpres, 0.0) * thickness;
    float2 sceneTex = distortedTex(rawTex, timeOffsetMulti*distortionStrength);
    float4 sceneColor = sample0(s0, sceneTex);

    float sobelDepth = SobelSampleDepth(s1, tex.xy, offset);

    float depth = readDepth(tex);
    float adjustedLineText = lineTest + (saturate(depth / 25000) * 500);

    sobelDepth = sobelDepth > adjustedLineText ? saturate(sobelDepth) : 0.0;
    sobelDepth = pow(saturate(sobelDepth) * OutlineDepthMultiplier, OutlineDepthBias);
    sobelDepth = step(0.01, sobelDepth);
    float sobelOutline = saturate(sobelDepth);

    float3 outColor = min(sceneColor.rgb * lineDarkMulti, lineDarkMax);

    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    bool aboveWater = water > waterlevel;

    float3 color = lerp(sceneColor.rgb, outColor, sobelOutline * aboveWater);

    return float4(color, sceneColor.a);
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 80;>
{
    pass a { PixelShader = compile ps_3_0 outline(); }
}
