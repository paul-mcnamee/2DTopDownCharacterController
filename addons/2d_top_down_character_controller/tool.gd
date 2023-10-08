@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("TopDownPlayerController2D", "CharacterBody2D", preload("2d_top_down_character_controller.gd"), null)


func _exit_tree():
	remove_custom_type("TopDownPlayerController2D")
