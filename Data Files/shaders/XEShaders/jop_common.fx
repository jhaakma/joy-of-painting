/**
    A collection of common functions and variables used by shaders in Joy of Painting.
**/

#define PI acos(-1)
#define sky 1e6

matrix mview;
matrix mproj;
float time;
float2 rcpres;
float3 sunvec;
float sunvis;
float3 eyepos;
float3 eyevec;
float fov;
float waterlevel;
float fogstart;
float fogrange;
float fognearrange;
float fognearstart;
float3 fognearcol;

// The inverse projection matrix
static const float2 invproj = 2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);

/**
    Samples a texture at the given texture coordinates, with mip level 0.
    @param s The texture sampler.
    @param uv The texture coordinates.
    @return The color of the pixel.
*/
float4 sample0(sampler2D s, float2 tex)
{
    return tex2Dlod(s, float4(tex, 0, 0));
}

/**
    Distorts the texture based on the provided distortion texture
    @param Tex The texture coordinates of the pixel.
    @param time The current time.
    @param speed The speed of the distortion.
    @param distance How far the distortion moves.
    @param scale The scale applied to the distortion texture.
    @param distortionStrength The strength of the distortion.
    @param sDistortionTex The distortion texture.
    @param offset The offset of the distortion. Default is 0.
*/
float2 distort(float2 Tex, float time, float distortionStrength, sampler2D sDistortionTex, float offset = 0) {

    float thisTime = time + offset;
    // Move around over time
    float2 uvR = float2(Tex.x + sin(thisTime * 0.5) * 0.1, Tex.y + cos(thisTime * 0.5) * 0.1) / 4.0;
    float2 uvG = float2(Tex.x + cos(thisTime * 0.5) * 0.1, Tex.y + sin(thisTime * 0.5) * 0.1) / 4.0 * 1.1;
    float2 uvB = float2(Tex.x - sin(thisTime * 0.5) * 0.1, Tex.y - cos(thisTime * 0.5) * 0.1) / 4.0 * 1.3;

    float4 normalMapR = tex2D(sDistortionTex, uvR);
    float4 normalMapG = tex2D(sDistortionTex, uvG);
    float4 normalMapB = tex2D(sDistortionTex, uvB);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortionR = (normalMapR.rg * 2.0 - 1.0);
    float2 distortionG = (normalMapG.rg * 2.0 - 1.0);
    float2 distortionB = (normalMapB.rg * 2.0 - 1.0);

    // Combine the distortions from each channel
    float2 combinedDistortion = (distortionR + distortionG + distortionB) / 3.0;

    // Apply the combined distortion to the texture coordinates
    float2 distort = Tex + combinedDistortion * distortionStrength;

    return distort;
}

/**
    Reads the depth of the pixel at the given texture coordinates.
    The returned depth is
    @param tex The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @param power The power to raise the depth to. Default is 1.
    @return The depth of the pixel.
*/
float readDepth(float2 tex, sampler2D sDepthFrame, int power = 1)
{
	float depth = pow(sample0(sDepthFrame, tex).r, power);
	return depth;
}

/**
    Convert RGB to HSL
    @param color The color to convert.
    @return The HSL color.
*/
float3 RGBToHSL(float3 color)
{
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value
    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0)       //This is a gray, no chroma...
    {
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
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

// Helper function for HSLToRGB
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

// Converts HSL to RGB
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

/**
    Converts the texture coordinates to world coordinates.
    @param tex The texture coordinates of the pixel.
    @return The world coordinates of the pixel.
*/
float3 toWorld(float2 tex)
{
	float3 v = float3(mview[0][2], mview[1][2], mview[2][2]);
	v += (1/mproj[0][0] * (2*tex.x-1)).xxx * float3(mview[0][0], mview[1][0], mview[2][0]);
	v += (-1/mproj[1][1] * (2*tex.y-1)).xxx * float3(mview[0][1], mview[1][1], mview[2][1]);
	return v;
}

/**
    Converts the texture coordinates to view coordinates.
    @param tex The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @return The view coordinates of the pixel.
*/
float3 toView(float2 tex, sampler2D sDepthFrame)
{
    float depth = readDepth(tex, sDepthFrame);
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

/**
    Gets the position of the pixel at the given texture coordinates.
    @param tex The texture coordinates of the pixel.
    @param depth The depth of the pixel.
    @param eyepos The position of the camera.
    @return The position of the pixel.
*/
float3 getPosition(float2 tex, float depth)
{
	return (eyepos + toWorld(tex) * depth);
}

/**
    Gets the world-space normal of the pixel at the given texture coordinates.
    @param uv The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @return The world-space normal of the pixel.
*/
float3 getWorldSpaceNormal(float2 uv, sampler2D sDepthFrame)
{
    // Neighboring UV coordinates
    float2 posCenter = uv;
    float2 posNorth  = posCenter + float2(0, -rcpres.y); // Move up
    float2 posEast   = posCenter + float2(rcpres.x, 0);  // Move right

    // Get view rays for the current pixel and neighbors
    float3 viewRayCenter = toWorld(posCenter); // This is a view ray, not world space position
    float3 viewRayNorth  = toWorld(posNorth);
    float3 viewRayEast   = toWorld(posEast);

    // Reconstruct world-space positions using eyePos
    float3 worldPosCenter = eyepos + normalize(viewRayCenter) * length(toView(posCenter, sDepthFrame));
    float3 worldPosNorth  = eyepos + normalize(viewRayNorth)  * length(toView(posNorth, sDepthFrame));
    float3 worldPosEast   = eyepos + normalize(viewRayEast)   * length(toView(posEast, sDepthFrame));

    // Compute the world-space normal using the cross product
    float3 edge1 = worldPosNorth - worldPosCenter;
    float3 edge2 = worldPosEast - worldPosCenter;

    // Correct for Z-up coordinate system
    float3 normal = normalize(cross(edge2, edge1)); // Switch cross order to respect Z-up
    return normal;
}