texture tex1 < string src="jop/hatchvt.tga"; >; // Your normal map texture
texture lastshader; // The texture you want to distort

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sNormalMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

extern float distortion_strength = 0.01; // Adjust this to change the strength of the distortion

float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Sample the input image and normal map
    float4 image = tex2D(sImage, Tex);
    float4 normalMap = tex2D(sNormalMap, Tex);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortion = (normalMap.rg * 2.0 - 1.0) * distortion_strength;

    // Apply the distortion to the texture coordinates
    float2 distortedTex = Tex + distortion;

    // Sample the image again with the distorted texture coordinates
    float4 final = tex2D(sImage, distortedTex);

    return final;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 20;  >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}
