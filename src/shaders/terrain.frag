uniform float cutoff;
uniform float topDepth;
uniform float bottomDepth;
uniform Image noise;
uniform Image gradient;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    vec4 baseNoise = Texel(noise, texture_coords);
    vec4 noiseColor = mix(vec4(0.6, 0.6, 0.6, 1), baseNoise, 0.5);
    noiseColor = noiseColor + vec4(0.2, 0.2, 0.2, 1);
    vec4 noisyBoundary = texturecolor * noiseColor;

    float depth = bottomDepth + (bottomDepth - topDepth) * texture_coords.y;

    if(noisyBoundary.r < cutoff) {
        if (texturecolor.r < cutoff) {
            if (texturecolor.g != 1 && texturecolor.b == 1) { //Hacky, set blue high to make an area open sky
                return vec4(0, 0, 0, 0);
            }
            float value = 0.5 + (texturecolor.r / cutoff) * 0.2;
            return Texel(gradient, vec2(depth, 0.5)) * vec4(value, value, value, 1);
        }
        else {
            if (texturecolor.r > cutoff - 0.1) {
                return Texel(gradient, vec2(depth, 0.5)) * vec4(0.8, 0.8, 0.8, 1);
            }
            return Texel(gradient, vec2(depth, 0.5)) * vec4(0.9, 0.9, 0.9, 1);
        }
    }
    else {
        float palleteSelect = depth + (baseNoise.r - 0.25) * 0.5;

        vec4 fillColor = Texel(gradient, vec2(palleteSelect, 0.5));
        return fillColor * color;
    }
}