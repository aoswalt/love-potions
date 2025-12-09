#pragma language glsl3

uniform int range = 10;

// https://github.com/glslify/glsl-easings/blob/master/cubic-out.glsl
float cubicOut(float t) {
  float f = t - 1.0;
  return f * f * f + 1.0;
}

vec4 effect(vec4 color_in, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 pixel = Texel(tex, texture_coords);

  vec2 pixelSize = 1.0 / textureSize(tex, 0).xy;

  vec4 sum = vec4(0);
  int halfRange = range / 2;

  for (int x = -halfRange; x <= halfRange; x++) {
    for (int y = -halfRange; y <= halfRange; y++) {
      sum += Texel(tex, texture_coords + vec2(x, y) * pixelSize);
    }
  }

  sum /= (range * range);

  // if pixel.a == 1 and any around != 1, it is the inside edge
  if(pixel.a == 1.0 && sum.a != 1.0) {
    vec4 hl = pixel;
    hl *= cubicOut(clamp(1.0 - sum.a, 0.0, 1.0));
    return pixel + hl;
  }

  if(pixel.a == 1.0) {
    return pixel;
  }

  sum.a *= 20.0;

  return sum;
}
