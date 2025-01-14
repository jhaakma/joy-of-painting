extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion
extern float speed = 0.5;
extern float scale = 1.5;
extern float distance = 0.1;
float time;

texture tex1 < string src="jop/perlinNoise.tga"; >; // Your normal map texture
texture lastshader; // The texture you want to distort
texture depthframe;
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sNormalMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sDepthFrame = sampler_state { texture = <depthframe>; addressu = wrap; addressv = wrap; magfilter = point; minfilter = point; };

float readDepth(in float2 coord : TEXCOORD0)
{
	float posZ = tex2D(sDepthFrame, coord).x;
	return posZ;
}

float4 distort(float2 Tex) {
    // Sample the input image and normal map
    float4 image = tex2D(sImage, Tex);
    //move around over time
    float2 uv = float2(Tex.x + sin(time*speed) * distance, Tex.y + cos(time*speed) * distance) / scale;

    float4 normalMap = tex2D(sNormalMap, uv);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortion = (normalMap.rg * 2.0 - 1.0) * distortionStrength;

    // Apply the distortion to the texture coordinates
    float2 distortedTex = Tex + distortion;

    // Sample the image again with the distorted texture coordinates
    float4 final = tex2D(sImage, distortedTex);

    return final;
}

float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    return distort(Tex);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 65;  >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}
