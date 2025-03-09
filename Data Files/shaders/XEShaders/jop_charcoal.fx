extern float hatchStrength = 0.2; //smaller value = lines are less prominent
float hatchSize = 1.0; //smaller value = smaller lines
float2 rcpres;

texture lastshader;
texture lastpass;
texture tex1 < string src="jop/pencil_tile.tga"; >;

sampler sImage = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sHatch = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sLastpass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};


float4 main(float2 Tex : TEXCOORD0) : COLOR0 {
    float4 color = tex2D(sImage, Tex);
    // Adjust the texture coordinates to match the pencil texture
    float2 adjustedTex = float2(Tex.x * rcpres.y / rcpres.x, Tex.y) *(1/hatchSize);
    // Sample the pencil texture
    float4 pencil = tex2D(sHatch, adjustedTex);

    // Apply the pencil effect
    float4 result = saturate((color+0.1) / (1-pencil));
    // Clamping the result to avoid overflow
    return lerp(color, result, hatchStrength);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 80; >
{
	pass p0
    {
        PixelShader = compile ps_3_0 main();
    }
}