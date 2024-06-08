//vtastek's Splash

float time;
float2 rcpres;
float3 sunvec;
float sunvis;
matrix mview;
matrix mproj;
float3 eyepos, eyevec;

//tweakables
//last value is coverage
float4 ColorBlend = float4(0.1,0.1,0.1,0.2);

//fade start-end, preferrably put 10-50 between for a smooth transition
float forge = 90;
float backgro = 100;
//50 is ~1 meters or so

//supress distant lines
float linend = 20000;

float3 Params = float3(0,1,1);

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
texture tex1 < string src="jop/emptytexscroll.tga"; >;
texture tex2 < string src="jop/hatchvt.tga"; >;

sampler sLastShader = sampler_state { texture=<lastshader>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sDepthFrame = sampler_state { texture=<depthframe>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};

sampler sScrollTex = sampler_state { texture=<tex1>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};
sampler sHatchTex = sampler_state { texture=<tex2>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=wrap; addressv = wrap;};

float readDepth(float2 tex)
{
	float depth = pow(tex2D(sDepthFrame, tex).r,1);
	return depth;
}
float3 toWorld(float2 tex)
{
	float3 v = float3(mview[0][2], mview[1][2], mview[2][2]);
	v += (1/mproj[0][0] * (2*tex.x-1)).xxx * float3(mview[0][0], mview[1][0], mview[2][0]);
	v += (-1/mproj[1][1] * (2*tex.y-1)).xxx * float3(mview[0][1], mview[1][1], mview[2][1]);
	return v;
}
float3 getPosition(in float2 tex, in float depth)
{
	return (eyepos + toWorld(tex) * depth);
}


float4 edgedetecting( float2 tex : TEXCOORD0  ) : COLOR0
{

	float depth = readDepth(tex);
	float3 pos2 = getPosition(tex, depth);

	float3 left2 = pos2 - getPosition(tex + rcpres.xy * float2(-1, 0), readDepth(tex + rcpres.xy * float2(-1, 0)));
	float3 right2 = getPosition(tex + rcpres.xy * float2(1, 0), readDepth(tex + rcpres.xy * float2(1, 0))) - pos2;
	float3 up2 = pos2 - getPosition(tex + rcpres.xy * float2(0, -1), readDepth(tex + rcpres.xy * float2(0, -1)));
	float3 down2 = getPosition(tex + rcpres.xy * float2(0, 1), readDepth(tex + rcpres.xy * float2(0, 1))) - pos2;

	float3 dx2 = length(left2) < length(right2) ? left2 : right2;
	float3 dy2 = length(up2) < length(down2) ? up2 : down2;

	float3 norm = normalize(cross(dx2,dy2));
	norm.z *= -1;

	float4 color = tex2D(sLastShader,tex.xy);

	color.r = round(color.r*ColorBlend.r)/ColorBlend.r;
	color.g = round(color.g*ColorBlend.g)/ColorBlend.g;
	color.b = round(color.b*ColorBlend.b)/ColorBlend.b;

	const float threshold = ColorBlend.w;

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


float4 BlurNormals(float2 UVCoord : TEXCOORD0, uniform float2 OffsetMask) : COLOR0
{

	float WeightSum = 0.12 * saturate(1 - Params.x);
	float4 oColor = tex2D(sLastPass,UVCoord);
	float4 finalColor = oColor * WeightSum;
	float depth = readDepth(UVCoord);

	for (int i = 0; i < cKernelSize; i++)
	{
		float2 uvOff = (BlurOffsets[i] * OffsetMask) * Params.y;
		float4 Color = tex2D(sLastPass, UVCoord + uvOff);
		float weight = saturate(dot(Color.xyz * 2 - 1, oColor.xyz * 2 - 1) - Params.x);
		finalColor += BlurWeights[i] * weight * Color;
		WeightSum += BlurWeights[i] * weight;
	}

	finalColor /= WeightSum;
	return float4(finalColor.rgb, oColor.a);

}


float4 splashblend( float2 Tex : TEXCOORD0 ) : COLOR0
{
	// depth blend masks
	float4 ce = smoothstep(forge, backgro, tex2D(sDepthFrame, Tex).r);

	ce.a = 0.0f;
	// original image, hatch. Hatch is animated.
	// hatch2 is single color from green channel to match
	float4 image = tex2D(sLastShader,Tex);
	float4 hatch = tex2D(sHatchTex,Tex + float2(fmod(time * 0.3 * sign(sin(time*12)),0.44), fmod(time * 0.4 * sign(sin(time*11)),0.33)));
	float4 hatch2 = tex2D(sHatchTex,Tex);// + fmod(time * 0.3 * sign(sin(time*100)),0.5));

	//shade data
	float obbright = max(0.0,dot(tex2D(sLastPass, Tex).rgb, -sunvec));
	obbright = lerp(1,obbright.xxx, sunvis);
	obbright = tex2D(sLastPass, Tex).rgb;


	//float4 mid = brown * saturate(100*(ce.r) * (1-ce.r));

	//image *=  * (1-ce.r));

	float lum = sqrt(dot(image * image, float3(0.29, 0.58, 0.114)));
	obbright = smoothstep(0.04, 0.05, lum.xxxx);

	float4 sky = image * saturate((1-ce.r));
	//return sky;

	float3 edges = tex2D(sLastPass,Tex + float2(0.0, 0.0)).a/2;


	edges += tex2D(sLastPass,Tex + float2( 0.5, 0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( -0.5, 0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( 0.5, -0.5) * (rcpres.y)).a/8;
	edges += tex2D(sLastPass,Tex + float2( -0.5, -0.5) * (rcpres.y)).a/8;
	edges = lerp(hatch2.g-0.5, edges, edges);

	edges = lerp(hatch.r, edges, obbright);



	float distmask = step(linend,tex2D(sDepthFrame, Tex));

	float4 empty = tex2D(sScrollTex,Tex);


	edges = saturate(edges + distmask);


	float3 final = lerp(sky.rgb , image.rgb, ce.r) * edges.rgb * edges.rgb;
	//final = lerp(image.rgb, empty.rgb, pow(lum, 1./2.2)) * pow(edges,2.2);

	final = 1.0 - (1.0 - final) * (1.0 - image);
	return float4(final.rgb,1);

	//return image;


}


technique T0 < string MGEinterface="MGE XE 0"; string category = "scene"; int priorityAdjust = 10000;  >
{
	pass p0 { PixelShader = compile ps_3_0 edgedetecting(); }
	//pass p1 { PixelShader = compile ps_3_0 BlurNormals( OffsetMaskH ); }
	//pass p2	{ PixelShader = compile ps_3_0 BlurNormals( OffsetMaskV ); }
	pass p3 { PixelShader = compile ps_3_0 splashblend(); }
}