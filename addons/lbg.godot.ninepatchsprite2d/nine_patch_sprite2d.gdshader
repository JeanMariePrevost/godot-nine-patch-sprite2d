shader_type canvas_item;
render_mode blend_mix;

//
// NinePatchSprite2D
// PLACEHOLDER!
//

uniform float patch_left;
uniform float patch_top;
uniform float patch_right;
uniform float patch_bottom;

// The scale of the sprite. Used because the shader cannot determine the size of the sprite.
uniform vec2 sprite_scale;

// Mode: 0 = Pixels (converted to UVs by script), 1 = UV Ratio
uniform int patch_mode;

void fragment() {
    // For now, behave exactly like a normal Sprite2D
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = tex_color * texture(TEXTURE, UV);
}
