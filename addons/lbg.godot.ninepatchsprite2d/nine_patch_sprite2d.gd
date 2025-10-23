# nine_patch_sprite2d.gd
## A Sprite2D subclass providing 9-slice (nine-patch) scaling through the use of a shader.

@tool
extends Sprite2D
class_name NinePatchSprite2D

## Draw the regions of the patch in the editor.
@export var debug_draw_patches: bool = false:
    set(value):
        debug_draw_patches = value
    get:
        return debug_draw_patches

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


func _ready() -> void:
    if not Engine.is_editor_hint():
        _init_material()
    else:
        call_deferred("_init_material")


func _process(_delta: float) -> void:
    # Push object scale to the shader
    _mat.set_shader_parameter("sprite_scale", scale)


func _draw() -> void:
    if debug_draw_patches and texture:
        var tex_size = texture.get_size()
        var effective_offset = offset
        if centered:
            effective_offset -= tex_size / 2.0

        # Convert patch values based on mode
        var left = patch_left
        var top = patch_top
        var right = patch_right
        var bottom = patch_bottom

        if patch_mode == 1:
            # Convert from UV ratios (0..1) to pixel coordinates
            left *= tex_size.x
            top *= tex_size.y
            right *= tex_size.x
            bottom *= tex_size.y

        # Convert right/bottom from "distance from edge" to actual coordinates
        right = tex_size.x - right
        bottom = tex_size.y - bottom

        # Draw the patch guides
        draw_line(Vector2(left, 0) + effective_offset, Vector2(left, tex_size.y) + effective_offset, Color.RED)
        draw_line(Vector2(right, 0) + effective_offset, Vector2(right, tex_size.y) + effective_offset, Color.RED)
        draw_line(Vector2(0, top) + effective_offset, Vector2(tex_size.x, top) + effective_offset, Color.RED)
        draw_line(Vector2(0, bottom) + effective_offset, Vector2(tex_size.x, bottom) + effective_offset, Color.RED)


func _init_material() -> void:
    if not _mat:
        _mat = ShaderMaterial.new()
        _mat.shader = preload("res://addons/lbg.godot.ninepatchsprite2d/nine_patch_sprite2d.gdshader")
        material = _mat
    _sync_shader()


## Used when changing inset "patch_mode" to make it more user-friendly
## It converts back and forth between pixels and UV ratios.
func _convert_patch_values() -> void:
    if not texture:
        return

    var tex_size = texture.get_size()

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
    if not _mat or not texture:
        return

    if material != _mat:
        push_error("Material is not the expected one. NinePatchSprite2D will not work properly. Did you replace the material?")
        return

    var tex_size: Vector2 = texture.get_size()
    if tex_size.x == 0 or tex_size.y == 0:
        return

    # Convert pixel insets to normalized UV if needed
    var fx = 1.0 / tex_size.x
    var fy = 1.0 / tex_size.y
    var left = patch_left * (fx if patch_mode == 0 else 1.0)
    var right = patch_right * (fx if patch_mode == 0 else 1.0)
    var top = patch_top * (fy if patch_mode == 0 else 1.0)
    var bottom = patch_bottom * (fy if patch_mode == 0 else 1.0)

    _mat.set_shader_parameter("patch_left", left)
    _mat.set_shader_parameter("patch_top", top)
    _mat.set_shader_parameter("patch_right", right)
    _mat.set_shader_parameter("patch_bottom", bottom)

    _mat.set_shader_parameter("patch_mode", patch_mode)

    queue_redraw()
