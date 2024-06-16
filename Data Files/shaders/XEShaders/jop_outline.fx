texture lastshader;
texture depthframe;
texture lastpass;

sampler s0 = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s1 = sampler_state { texture = <depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s2 = sampler_state { texture = <lastpass>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float2 rcpres;
float fogstart, fogrange, fognearrange, fognearstart;
float3 fognearcol;
matrix mproj;
float fov;
static float fogoffset = saturate(-fogstart / (fogrange - fogstart));

static const float2 invproj =  2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);

float OutlineThickness = 4.0;
float OutlineDepthMultiplier = 1.0;
float OutlineDepthBias = 1.0;

float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot = float2(1.0, 1/255.0);
    return dot( enc, kDecodeDot );
}

float3 DecodeViewNormalStereo( float4 enc4 )
{
    float kScale = 1.7777;
    float3 nn = enc4.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
    float g = 2.0 / dot(nn.xyz,nn.xyz);
    float3 n;
    n.xy = g*nn.xy;
    n.z = g-1;
    return n;
}

void DecodeDepthNormal(float4 enc, out float depth, out float3 normal)
{
    depth = DecodeFloatRG (enc.zw);
    normal = DecodeViewNormalStereo (enc);
}

float3 RGBtoHSL(float3 color)
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

float3 HSLtoRGB(float3 hsl)
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

float4 sample0(sampler2D s, float2 t)
{
    return tex2Dlod(s, float4(t, 0, 0));
}

float3 toView(float2 tex)
{
    float depth = sample0(s1, tex).r;
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

float LinearEyeDepth(float z)
{
	float c = mproj._33;
    float e = mproj._43;
    float near = - e / c;
	float far = -((c * near) / (1- c));
    float eyeDepth = far * near / ((near - far) * z + far);
	return (z);

}

float SobelDepth(float ldc, float ldl, float ldr, float ldu, float ldd)
{
	return (ldl - ldc) +
		(ldr - ldc) +
		(ldu - ldc) +
		(ldd - ldc);
}

float SobelSampleDepth(sampler s, float2 uv, float3 offset)
{
	float pixelCenter = LinearEyeDepth(sample0(s, uv).r);
	float pixelLeft = LinearEyeDepth(sample0(s, uv - offset.xz).r);
	float pixelRight = LinearEyeDepth(sample0(s, uv + offset.xz).r);
	float pixelUp = LinearEyeDepth(sample0(s, uv + offset.zy).r);
	float pixelDown = LinearEyeDepth(sample0(s, uv - offset.zy).r);

	return SobelDepth(pixelCenter, pixelLeft, pixelRight, pixelUp, pixelDown);
}


// Multiples of 4x7.5 work best
	#define dFontSize 1.0
	#define dDigits 1.0
	#define dDecimal 8.0


	float DigitBin( const int x )
	{
		return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
	}

	float PrintValue( float2 vStringCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
	{
		if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;

		bool bNeg = ( fValue < 0.0 );
		fValue = abs(fValue);

		float fLog10Value = log2(abs(fValue)) / log2(10.0);
		float fBiggestIndex = max(floor(fLog10Value), 0.0);
		float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
		float fCharBin = 0.0;
		if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
			if(fDigitIndex > fBiggestIndex) {
				if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
			} else {
				if(fDigitIndex == -1.0) {
					if(fDecimalPlaces > 0.0) fCharBin = 2.0;
				} else {
					float fReducedRangeValue = fValue;
					if(fDigitIndex < 0.0) { fReducedRangeValue = frac( fValue ); fDigitIndex += 1.0; }
					float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
					fCharBin = DigitBin(int(floor(fmod(fDigitValue, 10.0))));
				}
			}
		}
		return floor(fmod((fCharBin / pow(2.0, floor(frac(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
	}


	void printNum(float value, float2 coord, float fontsize, float digits, float decimals, float2 tex, inout float3 color)
	{
		float2 fs = float2(fontsize * 8, fontsize * 15)/400;
		float2 ftex = float2(tex.x, 1-tex.y);
		float2 ptex = float2(coord.x, 1-coord.y);
		float fIsDigit1 = PrintValue( (ftex - ptex) / fs, value, digits, decimals);
		color = lerp( color.rgb, float3(0.0, 1.0, 1.0), fIsDigit1);
	}



float4 outline(float2 tex : TEXCOORD0) : COLOR
{
	float3 offset = float3(rcpres, 0.0) * OutlineThickness;
	float4 sceneColor = sample0(s0, tex);

	float sobelDepth = SobelSampleDepth(s1, tex.xy, offset);
	sobelDepth = sobelDepth > 25.05 ? saturate(sobelDepth) : 0.0;
	sobelDepth = pow(saturate(sobelDepth) * OutlineDepthMultiplier, OutlineDepthBias);
	sobelDepth = step(0.01, sobelDepth);
	float sobelOutline = saturate(sobelDepth);

	float3 outColor = 0.0;
	float mask = sobelOutline;

	if(mask) {
		outColor = RGBtoHSL(pow(sceneColor,2.2));
		outColor.z *= 0.1;
		outColor = pow(HSLtoRGB(outColor), 1.0/2.2);
	}

	float dist = length(toView(tex));
    float fog = saturate((fognearrange - dist) / (fognearrange - fognearstart));

	float3 color = lerp(sceneColor.rgb, outColor, pow(fog,5.0) * sobelOutline);


 	return float4(color, sceneColor.a);
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 75;>
{
    pass a { PixelShader = compile ps_3_0 outline(); }
}
