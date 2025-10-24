// nine_patch_sprite2d.gdshader
// A shader for a 9-slice Sprite2D node similar to NinePatchRect, for Sprite2D nodes.
// Meant to be used with the NinePatchSprite2D custom node, but can be used without.
// However, if used without, you need to manually pass in the sprite_scale parameter,
// otherwise the border thickness cannot be kept constant.

shader_type canvas_item;
render_mode blend_mix;

// Patch insets, in UV space
// I.e. the thickness of the border as a ratio of the texture size
// Expects values between 0.0 and 1.0
uniform float patch_left;
uniform float patch_top;
uniform float patch_right;
uniform float patch_bottom;

// Sprite scale, passed in from the node
// Needed to correctly remap the UV coordinates to the texture space
// I.e. if the sprite is scaled, the UV coordinates need to be scaled inversely,
// because "0.1 of the texture size" refers to the _unscaled texture size_, not the size the sprite is actually displayed at
uniform vec2 sprite_scale = vec2(1.0);

// Modulate and self-modulate values, passed in from the node
// Needed to correctly apply the modulate and self-modulate values to the texture without having to deal with the alpha channel of the texture
uniform vec4 modulate = vec4(1.0);
uniform vec4 self_modulate = vec4(1.0);

// Debug visualization stuff
uniform bool debug_draw_regions = false; // Synced with the custom node's "debug_draw_regions" export
uniform float debug_line_thickness = 0.0025; // Thickness of the debug lines in UV
uniform vec4 debug_color = vec4(1.0, 0.0, 0.0, 1.0); // RGBA for the debug lines

void fragment() {
    // Store the UV coordinates of the current pixel normalized on the scaled quad
    // Needed because we need to work with _both_ the original UV coordinates and the remapped UV coordinates
    vec2 pos = UV; 

    // Compute scaled border coordinates (from texture UV to "scaled sprite UV")
    // Dividing by sprite_scale to compensate for the sprite scaling not actually
    // ending up as "scale", but rather "size" in 9-patch, keeping the border thickness constant.
    vec2 left_top = vec2(patch_left, patch_top) / sprite_scale;
    vec2 right_bottom = vec2(patch_right, patch_bottom) / sprite_scale;

    // Extract easier to use border size for each side
    float left_x   = left_top.x;
    float right_x  = 1.0 - right_bottom.x;
    float top_y    = left_top.y;
    float bottom_y = 1.0 - right_bottom.y;

    // Remapping
    // This is where we apply the mapping of the "scaled sprite UV" to the corect parts of the texture
    vec2 remapped_uv;

    // We remap each dimension separately, and combining the 3 horizontal and 3 vertical regions
    // is what gives us the "9-patches."
    // First processing left-to-right horizontal regions
    if (pos.x < left_x)
        remapped_uv.x = pos.x * sprite_scale.x;
    else if (pos.x > right_x)
        remapped_uv.x = 1.0 - (1.0 - pos.x) * sprite_scale.x;
    else {
        float t = (pos.x - left_x) / (right_x - left_x);
        remapped_uv.x = mix(patch_left, 1.0 - patch_right, t);
    }

    // Then processing top-to-bottom vertical regions
    if (pos.y < top_y)
        remapped_uv.y = pos.y * sprite_scale.y;
    else if (pos.y > bottom_y)
        remapped_uv.y = 1.0 - (1.0 - pos.y) * sprite_scale.y;
    else {
        float t = (pos.y - top_y) / (bottom_y - top_y);
        remapped_uv.y = mix(patch_top, 1.0 - patch_bottom, t);
    }

    // Final output, apply the texture to the pixel through the remapped UV,
    // and also apply the modulate and self-modulate values
    vec4 base_color = texture(TEXTURE, remapped_uv) * modulate * self_modulate;

    // Debug overlay stuff
    if (debug_draw_regions) {
        // Distance from any line
        float dx = min(abs(pos.x - left_x), abs(pos.x - right_x));
        float dy = min(abs(pos.y - top_y), abs(pos.y - bottom_y));
        float dist = min(dx, dy);

        // Draw only within the line thickness
        float line_mask = step(dist, debug_line_thickness);


        // Overlay the line, overriding both color and alpha
        base_color = mix(base_color, debug_color, line_mask * debug_color.a);
    }

    COLOR = base_color;
}
