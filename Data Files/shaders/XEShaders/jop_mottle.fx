extern float mottleStrength = 0.03;
extern float mottleSize = 1.0;
extern float sampleSpeed = 0.05;

float time;

texture lastshader;
texture tex1 < string src="jop/waterbrush.dds"; >;

sampler sLastShader = sampler_state { texture = <lastshader>; addressu = mirror; addressv = mirror; magfilter = linear; minfilter = linear; };
sampler sMottle = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; };


// Step 3 & 4: Apply Mottling Effect and Sample Mottle Texture
float3 applyMottlingEffect(float2 uv, float3 baseColor)
{
    float3 newColor = baseColor; // Initialize new color

    //Darken
    float2 randomUv1 = float2(uv.x + sin(time) * sampleSpeed, uv.y + cos(time) * sampleSpeed);
    float3 mottleColor1 = tex2D(sMottle, randomUv1 / mottleSize); // Sample mottle texture
    newColor = newColor + lerp(-mottleStrength, 0, mottleColor1.r);

    //Lighten
    float time2 = time * 0.5;
    float2 randomUv2 = float2(uv.x + sin(time2) * sampleSpeed, uv.y + cos(time2) * sampleSpeed);
    float3 mottleColor2 = tex2D(sMottle, randomUv2 / mottleSize); // Sample mottle texture
    newColor = newColor + lerp(0, mottleStrength, mottleColor2.g);

    return newColor; // Blend base color with mottled color
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
