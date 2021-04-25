uniform float innerCutoff;
uniform float outerCutoff;
uniform vec4 shadowColor;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);

    if(texturecolor.r < innerCutoff) {
            return vec4(0,0,0,0);
    }
    else if (texturecolor.r < outerCutoff) {
        float t = (outerCutoff - texturecolor.r) / (outerCutoff - innerCutoff);
        return mix(shadowColor, vec4(shadowColor.rgb, 0), t);
    }
    else {
        return shadowColor;
    }
}