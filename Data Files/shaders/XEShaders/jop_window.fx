// Aspect Ratio Shader
extern float aspectRatio = 1.0;
extern float view_port_size = 0.8;
float2 rcpres;
static const float screen_width = rcpres.x;
static const float screen_height = rcpres.y;

texture lastshader;
sampler2D s0 = sampler_state { texture = <lastshader>; addressu = clamp; };

float4 aspect_ratio(float2 tex: TEXCOORD0) : COLOR0
{
  // Calculate the aspect ratio of the screen
  float screenRatio = screen_width / screen_height;

  float new_width;
  float new_height;

  // Check if the screen has a wider or taller aspect ratio than the given width and height
  if (aspectRatio < screenRatio ) {
    // If the screen is wider than the given width and height, the rectangle should stretch to the width of the screen
    new_width = 1;
    new_height = 1 / (aspectRatio * screenRatio);
  } else {
    // If the screen is taller than the given width and height, the rectangle should stretch to the height of the screen
    new_width = aspectRatio * screenRatio;
    new_height = 1;
  }
  //Scale down so it doesn't take up the entire screen
  new_width = new_width * view_port_size;
  new_height = new_height * view_port_size;

  // Calculate the center of the screen
  float2 center = float2(0.5, 0.5);

  // Calculate the minimum and maximum x and y values for the rectangle
  float minX = center.x - new_width / 2;
  float maxX = center.x + new_width / 2;
  float minY = center.y - new_height / 2;
  float maxY = center.y + new_height / 2;

  // Check if the current pixel is outside of the rectangle
  if (tex.x < minX || tex.x > maxX || tex.y < minY || tex.y > maxY) {
    // If the pixel is outside of the rectangle, render it as black
    return float4(0, 0, 0, 1);
  } else {
    // If the pixel is inside the rectangle, render it normally
    return tex2D(s0, tex);
  }
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 10000; >
{
	pass p0 { PixelShader = compile ps_3_0 aspect_ratio(); }
}
