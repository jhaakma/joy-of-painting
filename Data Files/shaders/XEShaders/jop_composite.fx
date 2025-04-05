#include "jop_common.fx"

extern float distortionStrength = 0.05;
//When true, the overlay image will converted to black
extern float doBlackenImage = false;
//Higher values replace more of the overlay image with the canvas image
extern float compositeStrength = 0.0;
//The aspect ratio of the canvas window
extern float aspectRatio = 1.3;

//When true, the canvas window is rotated 90 degrees
extern float isRotated;
//The distance at which fog begins to obscure objects
extern float fogDistance = 250;
//If enabled, will use the alpha mask to create a vignette effect
extern int maskIndex = 0;
//If enabled, will use the alpha mask to create a sketch effect
extern int sketchMaskIndex = 0;
//The strength of the hatch effect
extern float hatchStrength = 0;
//The size of the hatch effect
extern float hatchSize = 1.0;

//The size of the canvas window
extern float diffThreshold = 0.05;
//The strength of the watercolor effect
extern float blendStrength = 1.0;
//The size of the watercolor effect
extern float waterColorDistortion = 0.1;

float maxDistance = 250-1;

texture lastshader;
texture lastpass;
texture depthframe;

//The composite texture, representing the canvas under the painting
texture tex1  < string src="jop/composite_tex.dds"; >;
//Alpha masks for the vignette effect
texture tex2 < string src="jop/vignetteAlphaMask.tga"; >;
texture tex3 < string src="jop/vignetteAlphaMask_2.tga"; >;
texture tex4 < string src="jop/vignetteAlphaMask_3.tga"; >;
texture tex5 < string src="jop/vignetteAlphaMask_4.tga"; >;
texture tex6 < string src="jop/perlinNoise.tga"; >;
texture tex7 < string src="jop/pencil_tile.tga"; >;

sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };
sampler2D sLastPass = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler2D sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler2D sComposite = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler2D sVignetteAlphaMask_1 = sampler_state { texture =<tex2>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; mipfilter = linear; };
sampler2D sVignetteAlphaMask_2 = sampler_state { texture =<tex3>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; mipfilter = linear; };
sampler2D sVignetteAlphaMask_3 = sampler_state { texture =<tex4>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; mipfilter = linear; };
sampler2D sVignetteAlphaSketchMask_1 = sampler_state { texture =<tex5>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; mipfilter = linear; };
sampler2D sDistortionMap = sampler_state { texture=<tex6>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler2D sHatch = sampler_state { texture=<tex7>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

/**
* Renders the canvas image on the screen, adjusting for aspect ratio and rotation.
* @param tex The texture coordinates of the pixel.
* @param image The canvas image.
* @param doRotate If true, the canvas window is rotated 90 degrees.
* @return The color of the pixel.
*/
float4 renderCanvas(float2 tex, sampler2D image, bool doRotate = false) : COLOR0
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
    if (doRotate) {
        float temp = new_width;
        new_width = new_height;
        new_height = temp;
    }

    // Calculate new bounds
    float2 newMin = float2(0.5, 0.5) - float2(new_width, new_height) / 2;
    float2 newMax = float2(0.5, 0.5) + float2(new_width, new_height) / 2;

    // Adjust tex coordinates for rotation
    float2 texCentered = tex - float2(0.5, 0.5);
    if (doRotate) {
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

        float4 canvas = tex2D(image, mappedTex);
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
    float4 canvas = renderCanvas(tex, sComposite, isRotated);
    float4 alphaMask_1 = renderCanvas(tex, sVignetteAlphaMask_1);
    float4 alphaMask_2 = renderCanvas(tex, sVignetteAlphaMask_2);
    float4 alphaMask_3 = renderCanvas(tex, sVignetteAlphaMask_3);

    float4 alphaSketchMask_1 = renderCanvas(tex, sVignetteAlphaSketchMask_1);

    float brightness = max(max(image.r, image.g), image.b);

    // Calculate the final image based on compositeStrength

    // Convert to black for sketches
    image = lerp(image, float4(0.01,0.01,0.01,image.a), doBlackenImage);

    float brightnessEffect = brightness;
    float canvasStrength = saturate(brightnessEffect * compositeStrength);

    if (hatchStrength > 0) {
        float2 hatchUV = float2(tex.x * rcpres.y / rcpres.x, tex.y) * (1/hatchSize);
        float4 hatch = tex2D(sHatch, hatchUV);
        canvasStrength = lerp(canvasStrength, 1.0, hatch.r * hatchStrength );
    }

    //Blend canvas into lighter areas
    image = lerp(image, canvas, canvasStrength);

    if (!doBlackenImage) {
        image.rgb = overlay(image.rgb, canvas.rgb, compositeStrength*0.1);
    }

    image = lerp(image, canvas, (1-alphaMask_1.a) * (maskIndex == 1));
    image = lerp(image, canvas, (1-alphaMask_2.a) * (maskIndex == 2));
    image = lerp(image, canvas, (1-alphaMask_3.a) * (maskIndex == 3));
    image = lerp(image, canvas, (1-alphaSketchMask_1.a) * (sketchMaskIndex == 1));

    // Cull distant objects
    float2 distTex = distort(tex, distortionStrength, sDistortionMap);
    float depth = readDepth(distTex, sDepthFrame);
    float distance_exp = pow(fogDistance, 2);
    float maxDistance_exp = pow(maxDistance, 2);
    float transitionD = 100 + fogDistance * 10;
    image = lerp(image, canvas, ( smoothstep(distance_exp, distance_exp + transitionD , depth ) * ( step(distance_exp, maxDistance_exp) )) );


    // Where the canvas has alpha, render as black
    image.rgb = lerp(0.001, image.rgb, canvas.a);

    return image;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 500; >
{
    pass p1 { PixelShader = compile ps_3_0 composite(); }
}
