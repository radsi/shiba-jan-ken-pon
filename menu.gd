extends Control

static var first_time = true
var colors := [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]

func _ready() -> void:
	if $Title/AnimationPlayer != null:
		$Title/AnimationPlayer.seek(0, true)
		$Title/AnimationPlayer.play("mainmenu")
	if first_time == false and $ColorRect2 != null:
		$ColorRect2.color.a = 1
		var tween = create_tween()
		tween.tween_property($ColorRect2, "color:a", 0, 1)

func _on_button_pressed() -> void:
	$AudioStreamPlayer2D.play()
	var tween = create_tween()
	
	var oni_rect = $Title/Oni/ColorRect
	var delay := 0.0
	var duration := 0.1
	
	for c in colors:
		tween.tween_property(oni_rect, "color", c, duration).set_delay(delay)
		delay += duration

	tween.tween_property($ColorRect2, "color:a", 1.2, 1)
	tween.tween_callback(Callable(self, "_on_fade_complete"))
	
	first_time = false

func _on_fade_complete() -> void:
	get_tree().change_scene_to_file("res://Scenes/arcade_control.tscn")

func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _on_buttonback_pressed() -> void:
	get_tree().change_scene_to_file("res://control.tscn")
