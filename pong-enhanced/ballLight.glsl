#pragma language glsl3

uniform vec2 ballPosition;
uniform int ballRadius;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 pixel = Texel(tex, texture_coords);

  float distance = length(screen_coords - ballPosition);
  float fade = clamp((distance - ballRadius) / ballRadius, 0.0, 1.0);

  color.a = 1.0 - fade;

  // return pixel * color;
  return color;
}
