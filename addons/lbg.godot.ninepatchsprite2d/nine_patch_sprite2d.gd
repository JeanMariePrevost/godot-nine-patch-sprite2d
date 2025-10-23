# nine_patch_sprite2d.gd
## A Sprite2D subclass providing 9-slice (nine-patch) scaling through the use of a shader.

@tool
extends Sprite2D
class_name NinePatchSprite2D

## Patch unit mode, whether to use pixels or UV ratio for the patch insets.
## E.g. you can have a "16px" border, or a "0.1 of the texture size" border.
@export_enum("Pixels", "UV Ratio") var patch_mode: int = 0:
    set(value):
        patch_mode = value
        _sync_shader()
    get:
        return patch_mode

## Patch inset values, or "thickness of the border." In pixels or UV ratio depending on the patch mode.
@export_group("Patch Insets")
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


func _init_material() -> void:
    if not _mat:
        _mat = ShaderMaterial.new()
        _mat.shader = preload("res://addons/lbg.godot.ninepatchsprite2d/nine_patch_sprite2d.gdshader")
        material = _mat
    _sync_shader()


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
