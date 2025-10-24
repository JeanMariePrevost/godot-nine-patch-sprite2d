# nine_patch_sprite2d.gd
## A Sprite2D subclass providing 9-slice (nine-patch) scaling through the use of a shader.

@tool
extends Sprite2D
class_name NinePatchSprite2D

## Draw the regions of the patch in the editor.
@export var debug_draw_regions: bool = false:
    set(value):
        debug_draw_regions = value
        material.set_shader_parameter("debug_draw_regions", value)
    get:
        return debug_draw_regions

## Whether to automatically sync the shader "scale" parameter with the node's scale.
## Turn off only if you need to achieve specific scaling behaviors.
@export var auto_sync_scale: bool = true:
    set(value):
        auto_sync_scale = value
    get:
        return auto_sync_scale

@export_group("Patch Insets")
## Patch unit mode, whether to use pixels or UV ratio for the patch insets.
## E.g. you can have a "16px" border, or a "0.1 of the texture size" border.
@export_enum("Pixels", "UV Ratio") var patch_mode: int = 0:
    set(value):
        patch_mode = value
        _convert_patch_values()
        _sync_shader()
    get:
        return patch_mode

## Patch inset values, or "thickness of the border." In pixels or UV ratio depending on the patch mode.
@export var patch_left: float = 8.0:
    set(value):
        patch_left = value
        _sync_shader()
    get:
        return patch_left

## Patch inset values, or "thickness of the border." In pixels or UV ratio depending on the patch mode.
@export var patch_top: float = 8.0:
    set(value):
        patch_top = value
        _sync_shader()
    get:
        return patch_top

## Patch inset values, or "thickness of the border." In pixels or UV ratio depending on the patch mode.
@export var patch_right: float = 8.0:
    set(value):
        patch_right = value
        _sync_shader()
    get:
        return patch_right

## Patch inset values, or "thickness of the border." In pixels or UV ratio depending on the patch mode.
@export var patch_bottom: float = 8.0:
    set(value):
        patch_bottom = value
        _sync_shader()
    get:
        return patch_bottom

################################
# Internal shader setup
################################
var _mat: ShaderMaterial

var _previous_modulate: Color = Color.WHITE
var _previous_self_modulate: Color = Color.WHITE


func _ready() -> void:
    if not Engine.is_editor_hint():
        _init_node()
    else:
        call_deferred("_init_node")


func _process(_delta: float) -> void:
    if not _mat:
        return

    # Push object scale to the shader
    if auto_sync_scale:
        _mat.set_shader_parameter("sprite_scale", scale)

    if modulate != _previous_modulate:
        _mat.set_shader_parameter("modulate", modulate)
        _previous_modulate = modulate
    if self_modulate != _previous_self_modulate:
        _mat.set_shader_parameter("self_modulate", self_modulate)
        _previous_self_modulate = self_modulate


func _init_material() -> void:
    if not _mat:
        _mat = ShaderMaterial.new()
        _mat.shader = preload("res://addons/lbg.godot.ninepatchsprite2d/nine_patch_sprite2d.gdshader")
        material = _mat


func _init_node() -> void:
    _init_material()
    _sync_shader()


## Used when changing inset "patch_mode" to make it more user-friendly
## It converts back and forth between pixels and UV ratios.
func _convert_patch_values() -> void:
    if not texture:
        return

    var tex_size = texture.get_size()

    print("Converting patch values.")

    # patch_mode is the new mode we just switched TO
    if patch_mode == 1:
        # We just switched TO UV-ratio mode, so convert from pixels → ratios
        patch_left /= tex_size.x
        patch_top /= tex_size.y
        patch_right /= tex_size.x
        patch_bottom /= tex_size.y
    else:
        # We just switched TO pixel mode, so convert from ratios → pixels
        patch_left *= tex_size.x
        patch_top *= tex_size.y
        patch_right *= tex_size.x
        patch_bottom *= tex_size.y


## Refreshes the shader with the current NinePatchSprite2D settings.
func _sync_shader() -> void:
    if not validate_or_refresh_material():
        return

    var tex_size: Vector2 = texture.get_size()
    if tex_size.x == 0 or tex_size.y == 0:
        return

    # Convert pixel insets to normalized UV if needed
    var effective_patch_left = patch_left
    var effective_patch_top = patch_top
    var effective_patch_right = patch_right
    var effective_patch_bottom = patch_bottom
    if patch_mode == 0:
        # We are in pixel mode, so convert from pixels → ratios
        effective_patch_left /= tex_size.x
        effective_patch_top /= tex_size.y
        effective_patch_right /= tex_size.x
        effective_patch_bottom /= tex_size.y

    _mat.set_shader_parameter("patch_left", effective_patch_left)
    _mat.set_shader_parameter("patch_top", effective_patch_top)
    _mat.set_shader_parameter("patch_right", effective_patch_right)
    _mat.set_shader_parameter("patch_bottom", effective_patch_bottom)

    _mat.set_shader_parameter("debug_draw_regions", debug_draw_regions)

    _mat.set_shader_parameter("modulate", modulate)
    _mat.set_shader_parameter("self_modulate", self_modulate)

    queue_redraw()


## Validates the material and refreshes it if needed.
## Returns true if the material is valid or was successfully re-initialized, false otherwise.
func validate_or_refresh_material() -> bool:
    if _mat == null:
        push_warning("Material was null during validation. Re-initializing.")
        _init_material()

    if _mat.shader == null:
        push_warning("Shader is missing from the material. Re-initializing.")
        _mat = null
        _init_material()

    if _mat != material:
        if material and material is ShaderMaterial:
            push_warning("Material was changed for another ShaderMaterial. Will try to use it instead.")
            _mat = material
        else:
            # Material was changed, but isn't valid for this node type
            push_warning("Material was changed or isn't valid. Reverting to the original material.")
            if _mat != null and _mat is ShaderMaterial:
                material = _mat
            else:
                _init_material()

    # Check that shader has expected parameters
    var uniforms_found: Array = _mat.shader.get_shader_uniform_list()
    var expected_uniforms: Array = ["patch_left", "patch_top", "patch_right", "patch_bottom", "sprite_scale", "modulate", "self_modulate", "debug_draw_regions"]

    # Convert to a set of just the found names for faster lookup
    var found_names := uniforms_found.map(func(u): return u.name)

    for uniform_name in expected_uniforms:
        if not found_names.has(uniform_name):
            push_error("Shader appears to be incorrect. Expected parameter '%s' not found." % uniform_name)
            return false
    return true
