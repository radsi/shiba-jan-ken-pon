extends Control

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/arcade.tscn")

func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _on_buttonback_pressed() -> void:
	get_tree().change_scene_to_file("res://control.tscn")
