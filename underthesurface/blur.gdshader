shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;
uniform float radius = 4.0;

void fragment() {
    vec2 pixel = 1.0 / vec2(textureSize(screen_tex, 0));
    vec4 col = vec4(0.0);
    float total = 0.0;

    for (float x = -radius; x <= radius; x++) {
        for (float y = -radius; y <= radius; y++) {
            float weight = 1.0 - length(vec2(x, y)) / radius;
            vec2 offset = vec2(x, y) * pixel;
            col += texture(screen_tex, SCREEN_UV + offset) * weight;
            total += weight;
        }
    }

    COLOR = col / total;
}