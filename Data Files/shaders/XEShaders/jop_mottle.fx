extern float mottleStrength = 0.03;
extern float mottleSize = 1.0;
extern float sampleSpeed = 0.5;
float2 rcpres;
float time;

texture lastshader;
texture tex1 < string src="jop/splash_watercolor.tga"; >;

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sMottle = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };


// Step 3 & 4: Apply Mottling Effect and Sample Mottle Texture
float3 applyMottlingEffect(float2 uv, float3 baseColor)
{
    float3 newColor = baseColor; // Initialize new color
    //newColor = float3(0,0,0);

    //LumEffect: mottle is stronger at low luminosity
    float luminosity = (newColor.r + newColor.g + newColor.b) / 3;
    float lumEffect = 1 - luminosity;

    //Lighten based on luminosity of mottle color
    float2 randomUv1 = float2(uv.x + sin(time * sampleSpeed) * 0.05, uv.y + cos(time* sampleSpeed) * 0.05);
    float3 mottleColor1 = tex2D(sMottle, randomUv1 / mottleSize); // Sample mottle texture

    //Squeeze the base color down by 10% and add the mottle color
    newColor = newColor + mottleColor1 * mottleStrength * lumEffect;

    return newColor; // Blend base color with mottled color
}



float4 main(float2 tex : TEXCOORD0) : COLOR0
{

    float3 color = tex2D(sLastShader, tex).rgb;

    // apply mottling
    float3 mottledColor = applyMottlingEffect(tex, color);

    return float4(mottledColor, 1);
}



technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 150;>
{
    pass a { PixelShader = compile ps_3_0 main(); }
}
