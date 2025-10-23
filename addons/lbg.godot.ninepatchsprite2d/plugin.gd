@tool
extends EditorPlugin

var node_script: Script = preload("res://addons/lbg.godot.ninepatchsprite2d/nine_patch_sprite2d.gd")
var node_icon: Texture2D = preload("res://addons/lbg.godot.ninepatchsprite2d/NinePatchRect.svg")


func _enter_tree() -> void:
    add_custom_type("NinePatchSprite2D", "Sprite2D", node_script, node_icon)  # Node name  # Base type  # GDScript file  # Icon for the scene tree


func _exit_tree() -> void:
    remove_custom_type("NinePatchSprite2D")
