extern float distortionStrength = 0.05; // Adjust this to change the strength of the distortion
extern float speed = 0.5;
extern float scale = 3;
extern float distance = 0.1;
float time;

texture tex1 < string src="jop/perlinNoise.tga"; >; // Your normal map texture
texture lastshader; // The texture you want to distort
sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sNormalMap = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

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


float4 main(float2 Tex : TEXCOORD0) : COLOR0
{
    // Apply the distortion to the texture coordinates
    float2 distTex = distort(Tex);

    // Sample the image again with the distorted texture coordinates
    float4 final = tex2D(sImage, distTex);

    return final;
}



technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 65;  >
{
    pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}
