float2 rcpres;

#define width rcpres.x
#define height rcpres.y
#define LineThickness 0.0003
#define SensitivityUpper 10
#define SensitivityLower 10
#define Saturation 1.5

texture lastshader;
texture depthframe;
texture lastpass;
texture tex1 < string src="jop/wclut.tga"; >;

sampler sLastShader = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler sLastPass = sampler_state { texture=<lastpass>; minfilter = linear; magfilter = linear; mipfilter = linear; addressu=clamp; addressv = clamp;};
sampler sLutTex = sampler_state { texture = <tex1>; addressu = wrap; addressv = wrap; magfilter = linear; minfilter = linear; mipfilter = NONE; };

#define PI acos(-1)

float3 RGBToHSL(float3 color)
{
	float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

	float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
	float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
	float delta = fmax - fmin;             //Delta RGB value

	hsl.z = (fmax + fmin) / 2.0; // Luminance

	if (delta == 0.0)		//This is a gray, no chroma...
	{
		hsl.x = 0.0;	// Hue
		hsl.y = 0.0;	// Saturation
	}
	else                                    //Chromatic data...
	{
		if (hsl.z < 0.5)
			hsl.y = delta / (fmax + fmin); // Saturation
		else
			hsl.y = delta / (2.0 - fmax - fmin); // Saturation

		float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
		float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
		float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

		if (color.r == fmax )
			hsl.x = deltaB - deltaG; // Hue
		else if (color.g == fmax)
			hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
		else if (color.b == fmax)
			hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

		if (hsl.x < 0.0)
			hsl.x += 1.0; // Hue
		else if (hsl.x > 1.0)
			hsl.x -= 1.0; // Hue
	}

	return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
	if (hue < 0.0)
		hue += 1.0;
	else if (hue > 1.0)
		hue -= 1.0;
	float res;
	if ((6.0 * hue) < 1.0)
		res = f1 + (f2 - f1) * 6.0 * hue;
	else if ((2.0 * hue) < 1.0)
		res = f2;
	else if ((3.0 * hue) < 2.0)
		res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
	else
		res = f1;
	return res;
}

float3 HSLToRGB(float3 hsl)
{
	float3 rgb;

	if (hsl.y == 0.0)
		rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
	else
	{
		float f2;

		if (hsl.z < 0.5)
			f2 = hsl.z * (1.0 + hsl.y);
		else
			f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

		float f1 = 2.0 * hsl.z - f2;

		rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
		rgb.g = HueToRGB(f1, f2, hsl.x);
		rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
	}

	return rgb;
}

float4 main(float2 tex : TEXCOORD0) : COLOR
{
	float dx =width/height * LineThickness;
	float dy =LineThickness;

	float4 c1 = tex2D(sLastShader, tex + float2(-dx,-dy));
	float4 c2 = tex2D(sLastShader, tex + float2(0,-dy));
	float4 c3 = tex2D(sLastShader, tex + float2(-dx,dy));
	float4 c4 = tex2D(sLastShader, tex + float2(-dx,0));
	float4 c5 = tex2D(sLastShader, tex + float2(0,0));
	float4 c6 = tex2D(sLastShader, tex + float2(dx,0));
	float4 c7 = tex2D(sLastShader, tex + float2(dx,-dy));
	float4 c8 = tex2D(sLastShader, tex + float2(0,dy));
	float4 c9 = tex2D(sLastShader, tex + float2(dx,dy));

	float4 c0 = (-c1-c2-c3-c4+c6+c7+c8+c9);

       float4 average = (c1 + c2 + c3 + c4 + c6 +  c7 + c8 + c9) - (c5 * 6);
	float av = (average .r + average .g + average .b) / 3;

	c0 = 1-abs((c0.r+c0.g+c0.b)/av);
        float val = pow(saturate((c0.r + c0.g + c0.b) / 3), SensitivityUpper);
	val = 1 - pow(1 - val, SensitivityLower);
        c0 = float4(val, val, val, val);


	c1 = tex2D(sLastShader,tex);

	float3 hsl = RGBToHSL(c1.xyz);
	hsl.g *= Saturation;
	c1 = float4(HSLToRGB(hsl),1);

	return c1 * c0;
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
	scene.rgb =  ClutFunc(scene.rgb, sLutTex);
	return scene;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
    pass p1 { PixelShader = compile ps_3_0 lut(); }
}
