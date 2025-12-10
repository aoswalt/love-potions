// https://blogs.love2d.org/content/let-it-glow-dynamically-adding-outlines-characters

#pragma language glsl3

uniform vec2 stepSize;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  float alpha = Texel(tex, texture_coords).a * 4;

  alpha -= Texel(tex, texture_coords + vec2(-stepSize.x,  0.0f)).a;
  alpha -= Texel(tex, texture_coords + vec2( stepSize.x,  0.0f)).a;
  alpha -= Texel(tex, texture_coords + vec2( 0.0f, -stepSize.y)).a;
  alpha -= Texel(tex, texture_coords + vec2( 0.0f,  stepSize.y)).a;

  vec4 newColor = vec4(0.2, 0.6, 1.0, alpha);

  return newColor;
}
