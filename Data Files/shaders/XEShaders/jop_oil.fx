#include "jop_common.fx"

float hatch_strength = 0.4;
extern float saturation = 0.5;
extern float contrast = 0.8;
extern float outlines = 0.1;




//fade start-end, preferrably put 10-50 between for a smooth transition
float forge = 90;
float backgro = 100;
//50 is ~1 meters or so


static const float2 OffsetMaskH = float2(1.0f, 0.0f);
static const float2 OffsetMaskV = float2(0.0f, 1.0f);

static const int cKernelSize = 24;

static const float BlurWeights[cKernelSize] =
{
	0.019956226f,
	0.031463016f,
	0.042969806f,
	0.054476596f,
	0.065983386f,
	0.077490176f,
	0.088996966f,
	0.100503756f,
	0.112010546f,
	0.135024126f,
	0.146530916f,
	0.158037706f,
	0.158037706f,
	0.146530916f,
	0.135024126f,
	0.112010546f,
	0.100503756f,
	0.088996966f,
	0.077490176f,
	0.065983386f,
	0.054476596f,
	0.042969806f,
	0.031463016f,
	0.019956226f
};

static const float2 BlurOffsets[cKernelSize] =
{
	float2(-12.0f * rcpres.x, -12.0f * rcpres.y),
	float2(-11.0f * rcpres.x, -11.0f * rcpres.y),
	float2(-10.0f * rcpres.x, -10.0f * rcpres.y),
	float2( -9.0f * rcpres.x,  -9.0f * rcpres.y),
	float2( -8.0f * rcpres.x,  -8.0f * rcpres.y),
	float2( -7.0f * rcpres.x,  -7.0f * rcpres.y),
	float2( -6.0f * rcpres.x,  -6.0f * rcpres.y),
	float2( -5.0f * rcpres.x,  -5.0f * rcpres.y),
	float2( -4.0f * rcpres.x,  -4.0f * rcpres.y),
	float2( -3.0f * rcpres.x,  -3.0f * rcpres.y),
	float2( -2.0f * rcpres.x,  -2.0f * rcpres.y),
	float2( -1.0f * rcpres.x,  -1.0f * rcpres.y),
	float2(  1.0f * rcpres.x,   1.0f * rcpres.y),
	float2(  2.0f * rcpres.x,   2.0f * rcpres.y),
	float2(  3.0f * rcpres.x,   3.0f * rcpres.y),
	float2(  4.0f * rcpres.x,   4.0f * rcpres.y),
	float2(  5.0f * rcpres.x,   5.0f * rcpres.y),
	float2(  6.0f * rcpres.x,   6.0f * rcpres.y),
	float2(  7.0f * rcpres.x,   7.0f * rcpres.y),
	float2(  8.0f * rcpres.x,   8.0f * rcpres.y),
	float2(  9.0f * rcpres.x,   9.0f * rcpres.y),
	float2( 10.0f * rcpres.x,  10.0f * rcpres.y),
	float2( 11.0f * rcpres.x,  11.0f * rcpres.y),
	float2( 12.0f * rcpres.x,  12.0f * rcpres.y)
};


texture lastshader;
texture depthframe;
texture lastpass;

//this is background texture inside textures folder
texture tex2 < string src="jop/hatchvt.tga"; >;

sampler sLastShader = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDepthFrame = sampler_state { texture=<depthframe>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sHatchTex = sampler_state { texture=<tex2>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};


float4 edgedetecting( float2 tex : TEXCOORD0  ) : COLOR0
{

	float depth = readDepth(tex, sDepthFrame);
	float3 pos2 = getPosition(tex, depth);

	float3 left2 = pos2 - getPosition(tex + rcpres.xy * float2(-1, 0), readDepth(tex + rcpres.xy * float2(-1, 0), sDepthFrame));
	float3 right2 = getPosition(tex + rcpres.xy * float2(1, 0), readDepth(tex + rcpres.xy * float2(1, 0), sDepthFrame)) - pos2;
	float3 up2 = pos2 - getPosition(tex + rcpres.xy * float2(0, -1), readDepth(tex + rcpres.xy * float2(0, -1), sDepthFrame));
	float3 down2 = getPosition(tex + rcpres.xy * float2(0, 1), readDepth(tex + rcpres.xy * float2(0, 1), sDepthFrame)) - pos2;

	float3 dx2 = length(left2) < length(right2) ? left2 : right2;
	float3 dy2 = length(up2) < length(down2) ? up2 : down2;

	float3 norm = normalize(cross(dx2,dy2));
	norm.z *= -1;

	float4 color = tex2D(sLastShader,tex.xy);

	// color.r = round(color.r*ColorBlend.r)/ColorBlend.r;
	// color.g = round(color.g*ColorBlend.g)/ColorBlend.g;
	// color.b = round(color.b*ColorBlend.b)/ColorBlend.b;

	const float threshold = outlines;

	const int NUM = 9;
	const float2 c[NUM] =
	{
		float2(-0.0078125, 0.0078125),
		float2( 0.00 ,     0.0078125),
		float2( 0.0078125, 0.0078125),
		float2(-0.0078125, 0.00 ),
		float2( 0.0,       0.0),
		float2( 0.0078125, 0.007 ),
		float2(-0.0078125,-0.0078125),
		float2( 0.00 ,    -0.0078125),
		float2( 0.0078125,-0.0078125),
	};

	int i;
	float3 col[NUM];
	for (i=0; i < NUM; i++)
	{
		col[i] = tex2D(sLastShader, tex.xy + 0.2*c[i]);
	}

	float3 rgb2lum = float3(0.30, 0.59, 0.11);
	float lum[NUM];
	for (i = 0; i < NUM; i++)
	{
		lum[i] = dot(col[i].xyz, rgb2lum);
	}
	float x = lum[2]+  lum[8]+2*lum[5]-lum[0]-2*lum[3]-lum[6];
	float y = lum[6]+2*lum[7]+  lum[8]-lum[0]-2*lum[1]-lum[2];
	float edge =(x*x + y*y < threshold)? 1.0:0.0;


	return float4(norm.xyz,edge);

}



float4 splashblend( float2 Tex : TEXCOORD0 ) : COLOR0
{
	// original image, hatch. Hatch is animated.
	// hatch2 is single color from green channel to match
	float4 image = tex2D(sLastShader,Tex);
	float4 hatch = tex2D(sHatchTex,Tex + float2(fmod(time * 0.3 * sign(sin(time*12)),0.44), fmod(time * 0.4 * sign(sin(time*11)),0.33)));
	float4 hatch2 = tex2D(sHatchTex,Tex + fmod(time * 0.3 * sign(sin(time*100)),0.5));

	//shade data
	float obbright = max(0.0,dot(tex2D(sLastPass, Tex).rgb, -sunvec));
	obbright = lerp(1,obbright.xxx, sunvis);
	obbright = tex2D(sLastPass, Tex).rgb;


	float lum = sqrt(dot(image.rgb * image.rgb, float3(0.29, 0.58, 0.114)));
	obbright = smoothstep(0.04, hatch_strength, lum.xxxx);

	float3 edges = tex2D(sLastPass,Tex + float2(0.0, 0.0)).a/2;

	edges += tex2D(sLastPass,Tex + float2( 0.5, 0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( -0.5, 0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( 0.5, -0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( -0.5, -0.5) * (rcpres.y)).a/8;
	edges = lerp(hatch2.g-0.5, edges, edges);

	edges = lerp(image.r, edges, obbright);

	float3 final = image.rgb * edges.rgb * edges.rgb;

	final = 1.0 - (1.0 - final) * (1.0 - image.rgb);

    //Reduce contrast
    final = final * contrast;
    //Increase saturation
    final.rgb = applyVibrance(final.rgb, saturation);
	return float4(final.rgb,1);
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 70;  >
{
	pass p0 { PixelShader = compile ps_3_0 edgedetecting(); }
	pass p3 { PixelShader = compile ps_3_0 splashblend(); }
}
