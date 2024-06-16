#define Saturation 1.0
extern float sensitivity = 20;
extern float inkThickness = 0.0005;
extern float distance = 250;
extern float maxDistance = 250-1;
texture lastshader;
texture lastpass;
texture depthframe;
float2 rcpres;
sampler sLastShader = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sDepthFrame = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};

#define width rcpres.x
#define height rcpres.y

float readDepth(float2 tex)
{
    float depth = pow(tex2D(sDepthFrame, tex).r,1);
    return depth;
}


float4 edge_detect(float2 tex : TEXCOORD0) : COLOR
{
    float dx =width/height * inkThickness;
    float dy =inkThickness;

    float4 c1 = tex2D(sLastPass, tex + float2(-dx,-dy));
    float4 c2 = tex2D(sLastPass, tex + float2(0,-dy));
    float4 c3 = tex2D(sLastPass, tex + float2(-dx,dy));
    float4 c4 = tex2D(sLastPass, tex + float2(-dx,0));
    float4 c5 = tex2D(sLastPass, tex + float2(0,0));
    float4 c6 = tex2D(sLastPass, tex + float2(dx,0));
    float4 c7 = tex2D(sLastPass, tex + float2(dx,-dy));
    float4 c8 = tex2D(sLastPass, tex + float2(0,dy));
    float4 c9 = tex2D(sLastPass, tex + float2(dx,dy));

    float4 c0 = (-c1-c2-c3-c4+c6+c7+c8+c9);

    float4 average = (c1 + c2 + c3 + c4 + c6 +  c7 + c8 + c9) - (c5 * 6);
    float av = (average .r + average .g + average .b) / 3;

    c0 = 1-abs((c0.r+c0.g+c0.b)/av);
        float val = pow(saturate((c0.r + c0.g + c0.b) / 3), sensitivity);
    val = 1 - pow(1 - val, sensitivity);

    float3 gray = float3(val, val, val);

    float3 blackWhite = saturate(gray * Saturation);
    return float4(blackWhite, 1.0);
}


technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 70;>
{
    pass p1 { PixelShader = compile ps_3_0 edge_detect(); }
}
