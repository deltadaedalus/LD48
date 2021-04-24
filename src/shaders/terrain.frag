uniform float cutoff;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);

    if(texturecolor.r < cutoff) {
        return vec4(0,0,0,0);
    }
    else {
        vec4 fillColor = vec4(1, 1, 1, 1);
        return fillColor * color;
    }
}