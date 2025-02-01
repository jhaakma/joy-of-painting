#include "jop_common.fx"

#define width rcpres.x
#define height rcpres.y
#define SensitivityUpper 10
#define SensitivityLower 10
extern float Saturation = 0.2;

extern int selectedLut = 1;
extern float LineThickness = 0.0003;

texture lastshader;
texture lastpass;

texture tex1 < string src="jop/luts/neutral.tga"; >;
texture tex2 < string src="jop/luts/saturated.tga"; >;
texture tex3 < string src="jop/luts/desaturated.tga"; >;
texture tex4 < string src="jop/luts/warm.tga"; >;
texture tex5 < string src="jop/luts/cold.tga"; >;
texture tex6 < string src="jop/luts/hueShifted_1.tga"; >;
texture tex7 < string src="jop/luts/hueShifted_2.tga"; >;
texture tex8 < string src="jop/luts/hueShifted_3.tga"; >;
texture tex9 < string src="jop/luts/sepia.tga"; >;
texture tex10 < string src="jop/luts/radioactive.tga"; >;

sampler sLastShader = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLutTex1 = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex2 = sampler_state { texture = <tex2>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex3 = sampler_state { texture = <tex3>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex4 = sampler_state { texture = <tex4>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex5 = sampler_state { texture = <tex5>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex6 = sampler_state { texture = <tex6>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex7 = sampler_state { texture = <tex7>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex8 = sampler_state { texture = <tex8>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex9 = sampler_state { texture = <tex9>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };
sampler sLutTex10 = sampler_state { texture = <tex10>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };

float4 main(float2 tex : TEXCOORD0) : COLOR
{

    //Add some saturation
    float4 c1 = tex2D(sLastShader,tex);
    float3 hsl = RGBToHSL(c1.xyz);
    hsl.g = saturate(hsl.g + Saturation * (1 - hsl.g));
    c1 = float4(HSLToRGB(hsl),1);
    return c1;
}


float3 ClutFunc( float3 colorIN, sampler2D LutSampler )
{
    float2 CLut_pSize = float2(0.00390625, 0.0625);// 1 / float2(256, 16);
    float4 CLut_UV;
    colorIN    = saturate(colorIN) * 15.0;
    CLut_UV.w  = floor(colorIN.b);
    CLut_UV.xy = (colorIN.rg + 0.5) * CLut_pSize;
    CLut_UV.x += CLut_UV.w * CLut_pSize.y;
    CLut_UV.z  = CLut_UV.x + CLut_pSize.y;
    return lerp( tex2Dlod(LutSampler, CLut_UV.xyzz).rgb, tex2Dlod(LutSampler, CLut_UV.zyzz).rgb, colorIN.b - CLut_UV.w);
}

float4 lut(in float2 tex:TEXCOORD0): COLOR0
{
    float4 scene = tex2D(sLastPass,tex);
    // apply the selected LUT
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex1), selectedLut == 1);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex2), selectedLut == 2);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex3), selectedLut == 3);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex4), selectedLut == 4);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex5), selectedLut == 5);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex6), selectedLut == 6);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex7), selectedLut == 7);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex8), selectedLut == 8);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex9), selectedLut == 9);
    scene.rgb = lerp(scene.rgb, ClutFunc(scene.rgb, sLutTex10), selectedLut == 10);
    return scene;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 55; >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
    //pass p1 { PixelShader = compile ps_3_0 lut(); }
}
