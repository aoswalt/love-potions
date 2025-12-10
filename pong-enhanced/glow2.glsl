// https://godotshaders.com/shader/outline-and-glow-shader-sprite-3d/
// an example of varying samples, scale, etc. for glow

#pragma language glsl3

uniform vec4 line_color  = vec4(1.0,1.0,1.0,1.0); // Glow or outline color : source_color
uniform float glowSize = 15.0; // Size of glow : hint_range(0.0, 300)
uniform int glowDensity = 3; // How many stamps to repeat in one direction : hint_range(0, 30)
uniform int glowRadialCoverage = 4; // How many directions to spread out : hint_range(0, 32)
uniform float glowAngle = 1.57; // The starting angle. More important if you want to use this as a trail. : hint_range(0.0, 6.28)
uniform float glowSharpness = 1.0; // Effect how quickly stamps become transparent as they move out : hint_range(0.0, 5.0)
uniform float alphaThreshold =  0.2; // : hint_range(0.0, 1.0)

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 col = Texel(tex, texture_coords);

  // Sets source image as default pixel
  vec3 ALBEDO = col.rgb;
  float ALPHA = col.a;

  vec2 pixel_size = 1.0 / vec2(textureSize(tex, 0)); // Set pixel size
  float alph = 0;

  for (int i = 0; i < glowRadialCoverage; i++) { // Goes around in a circle
    for (int j = 0; j < glowDensity; j++) { // Extends out
      float radians360 = 3.141592 * 2;
      // The angle from which to grab pixel information
      float angle = (radians360 / float(glowRadialCoverage))*float(i+1) + glowAngle;
      // The distance to reach to grab pixel information
      float dist = glowSize * float(j + 1) / float(glowDensity);
      // Pixel coordinate to grab
      vec2 pixel_coor = vec2( sin(angle) , cos(angle) );
      // Gets the pixel based on the previous information
      vec4 tex = Texel(tex, texture_coords + pixel_coor * pixel_size * dist);

      // Sharpness. If you don't care about this, enable the next line and delete the next 3
      // alph += tex.a * line_color.a;
      float distFrom = float(glowDensity-j) / float(glowDensity); // Distance iteration number (how far out)
      float sharpness = mix(0.0, 1.0, pow(distFrom, glowSharpness) ); // Figure out sharpness level, interplote with distance and Glow Sharpness modifier
      alph += (tex.a * line_color.a) * sharpness; // Apply sharpness
    }
  }

  // vec4 newColor = vec4(0.2, 0.6, 1.0, alph);

    // Adds outline if this part of the image is transparent
  if (ALPHA < alphaThreshold){
    ALBEDO = line_color.rgb;
    ALPHA = alph;
  }

  return vec4(ALBEDO.x, ALBEDO.y, ALBEDO.z, ALPHA);
}
