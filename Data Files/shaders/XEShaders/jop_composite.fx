//When true, the overlay image will converted to black
extern float doBlackenImage = false;
//Higher values replace more of the overlay image with the canvas image
extern float compositeStrength = 0.0;
//The aspect ratio of the canvas window
extern float aspectRatio = 1.0;
//The size of the canvas window as a percentage of the screen
extern float viewportSize = 0.8;
//When true, the canvas window is rotated 90 degrees
extern float isRotated;
//The distance at which fog begins to obscure objects
extern float fogDistance = 250;

float maxDistance = 250-1;
float2 rcpres;
static const float screen_width = rcpres.x;
static const float screen_height = rcpres.y;

texture lastshader;
texture lastpass;
texture depthframe;
texture tex1  < string src="jop/composite_tex.dds"; >;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler2D sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler2D sComposite = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float readDepth(float2 tex)
{
	float depth = pow(tex2D(sDepthFrame, tex).r,1);
	return depth;
}

float4 renderCanvas(float2 tex : TEXCOORD0) : COLOR0
{
    // Calculate the aspect ratio of the screen
    float screenRatio = screen_width / screen_height;
    float new_width, new_height;

    // Adjust window size based on aspect ratio
    if (aspectRatio < screenRatio) {
        new_width = viewportSize;
        new_height = viewportSize / (aspectRatio * screenRatio);
    } else {
        new_width = viewportSize * aspectRatio * screenRatio;
        new_height = viewportSize;
    }

    // Adjust for rotation
    if (isRotated) {
        float temp = new_width;
        new_width = new_height;
        new_height = temp;
    }

    // Calculate new bounds
    float2 newMin = float2(0.5, 0.5) - float2(new_width, new_height) / 2;
    float2 newMax = float2(0.5, 0.5) + float2(new_width, new_height) / 2;

    // Adjust tex coordinates for rotation
    float2 texCentered = tex - float2(0.5, 0.5);
    if (isRotated) {
        texCentered = float2(texCentered.y, -texCentered.x);
    }
    float2 rotatedTex = texCentered + float2(0.5, 0.5);

    // Check if pixel is outside new bounds
    if (rotatedTex.x < newMin.x || rotatedTex.x > newMax.x || rotatedTex.y < newMin.y || rotatedTex.y > newMax.y) {
        return float4(0.00, 0.00, 0.00, 0); // Render pixel as black
    } else {
        // Map texture coordinates to new bounds
        float2 mappedTex;
        mappedTex.x = (rotatedTex.x - newMin.x) / (newMax.x - newMin.x);
        mappedTex.y = (rotatedTex.y - newMin.y) / (newMax.y - newMin.y);

        float4 canvas = tex2D(sComposite, mappedTex);
        //Where the canvas has alpha, render as black
        if (canvas.a < 0.5) {
            return float4(0.01, 0.01, 0.01, 0);
        }
        return canvas; // Render pixel with mapped and rotated texture coordinates
    }
}

//This takes composites the sLastShader onto the result of sLastPass.
//It renders the sLastShader transparent based on brightness and the compositeStrength.
//At 0 compositeStrength, the sLastShader is invisible.
//At 1 compositeStrength, the sLastShader is fully visible.
float4 composite(float2 tex : TEXCOORD0) : COLOR0
{
    float4 image = tex2D(sLastShader, tex);
    float4 composite = tex2D(sLastPass, tex);

    // Calculate the brightness of the sLastShader
    float brightness = dot(image.rgb, float3(0.299, 0.587, 0.114));

    // Calculate the final image based on compositeStrength
    float4 overlay = lerp(image, float4(0.01,0.01,0.01,image.a), doBlackenImage);
    float4 result = lerp(overlay, composite, saturate(brightness * compositeStrength));

    // Cull distant objects
    float depth = readDepth(tex);
    float distance_exp = pow(fogDistance, 2);
    float maxDistance_exp = pow(maxDistance, 2);
    float transitionD = 100 + fogDistance * 10;
    result = lerp(result, composite, ( smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) )) );

    // Where the composite has alpha, render as black
    result.rgb = lerp(0.01, result.rgb, composite.a);

    return result;
}



//priority adjusted to 100,000,000 above final because this REALLY can not be overwritten without breaking the mod
technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 500; >
{
	pass p0 { PixelShader = compile ps_3_0 renderCanvas(); }
    pass p1 { PixelShader = compile ps_3_0 composite(); }
}
