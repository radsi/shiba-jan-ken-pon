extends Node2D

@onready var labels_group = $GameLabels
@onready var hands_group = $Hands
@onready var head_root = $Heads
@onready var head_sprite = $Heads/Head

@export var colors: Array = [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]
@export var display_time: float = 3
@export var gameinfo_display_time: float = 1.0
@export var speedup_step: float = 0.05

var clones: Array = []
var time_accum: float = 0.0
var intro_ended = false
var CPUPoints = 0
var PlayerPoints = 0
var sequence: Array = ["Jan", "Ken", "Pon"]
var sequence_index = 0

var player_move: int = -1
var player_combo = 0
var result_shown = false
var result_timer: float = 0.0
var cpu_move: int = -1
var original_hand_frame: int
var original_hand_flip_h: bool
var game_over = false
var game_round = 1

var head_start_pos: Vector2
var head_start_rot: float = 0
var enemy_textures: Array = []

var shaking := false

# ------------------------------
# SETUP
# ------------------------------
func _ready():
	_init_labels()
	_save_original_hand()
	_load_enemy_textures("res://Enemies/")
	_change_head_texture()

func _init_labels():
	clones = labels_group.get_children().filter(func(c): return c is Label)
	for i in clones.size():
		var lbl: Label = clones[i]
		var color_index = int(remap(i, 0, clones.size()-1, 0, colors.size()-1))
		lbl.modulate = colors[color_index]
		lbl.text = clones[0].text
		lbl.visible = true

func _save_original_hand():
	var second_hand = hands_group.get_child(1)
	if second_hand is Sprite2D:
		original_hand_frame = second_hand.frame
		original_hand_flip_h = second_hand.flip_h

func _load_enemy_textures(dir: String):
	var da = DirAccess.open(dir)
	if not da: return
	da.list_dir_begin()
	while true:
		var f = da.get_next()
		if f == "": break
		if f.ends_with(".png"):
			enemy_textures.append(load(dir + f))
	da.list_dir_end()

# ------------------------------
# MAIN LOOP
# ------------------------------
func _process(delta):
	time_accum += delta
	_update_label_wobble()

	if game_over: return

	_check_player_input()
	_handle_intro()
	_handle_sequence(delta)
	_handle_result(delta)

func _update_label_wobble():
	for i in clones.size():
		if clones[i].visible:
			clones[i].rotation_degrees = 4.0 * sin((time_accum - i * 0.1) * 2.0)

func _check_player_input():
	if Input.is_action_just_pressed("ui_left"): player_move = 0
	elif Input.is_action_just_pressed("ui_up"): player_move = 1
	elif Input.is_action_just_pressed("ui_right"): player_move = 2

func _handle_intro():
	if not intro_ended and time_accum >= (display_time - gameinfo_display_time + 1):
		intro_ended = true
		for lbl in clones: lbl.visible = false
		for hand in hands_group.get_children():
			if hand is Sprite2D: hand.frame = 12
		time_accum = 0.0

func _handle_sequence(delta):
	if intro_ended and sequence_index < sequence.size():
		for lbl in clones:
			lbl.visible = true
			lbl.text = sequence[sequence_index]
		if time_accum >= gameinfo_display_time:
			time_accum = 0.0
			sequence_index += 1
	elif intro_ended and sequence_index >= sequence.size() and not result_shown:
		_show_result()

func _handle_result(delta):
	if result_shown:
		result_timer += delta
		if result_timer >= gameinfo_display_time:
			if abs(PlayerPoints - CPUPoints) >= 9:
				_game_over()
			else:
				gameinfo_display_time = max(0.25, gameinfo_display_time - speedup_step)
				_reset_loop()

# ------------------------------
# RESULTADOS
# ------------------------------
func _show_result():
	cpu_move = randi() % 3
	_update_cpu_hand()
	var result_text := _determine_winner()
	for lbl in clones: lbl.text = result_text
	for lbl in $PointsLabels.get_children():
		lbl.text = "%s - %s" % [PlayerPoints, CPUPoints]
	if player_combo >= 2:
		for lbl in $ComboLabels.get_children():
			lbl.visible = true
			lbl.text = "x%s" % player_combo
	else:
		for lbl in $ComboLabels.get_children():
			lbl.visible = false
	result_shown = true
	result_timer = 0.0
	if gameinfo_display_time < 0.75: $Smokes/SmokePlayer.play("smoke_anim") 
	else: $Smokes/SmokePlayer.stop()
	if gameinfo_display_time < 0.5: start_head_shake() 
	else: stop_head_shake()

func _update_cpu_hand():
	for lbl in clones: lbl.visible = false
	var second_hand := hands_group.get_child(1) as Sprite2D
	if not second_hand: return
	match cpu_move:
		0: second_hand.frame = 13; second_hand.flip_h = false
		1: second_hand.frame = 0; second_hand.flip_h = false
		2: second_hand.frame = 11; second_hand.flip_h = true

func _determine_winner() -> String:
	var result_text := "I win"
	CPUPoints += 1
	speedup_step = 0
	if player_move != -1:
		if player_move == cpu_move:
			result_text = "Draw"
			speedup_step = 0.05
			CPUPoints -= 1
		elif (player_move == 0 and cpu_move == 2) or \
			 (player_move == 1 and cpu_move == 0) or \
			 (player_move == 2 and cpu_move == 1):
			result_text = "You win"
			player_combo += 1
			if player_combo >= 2: speedup_step = -0.05
			PlayerPoints += 1
			CPUPoints -= 1
	if result_text == "I win":
		player_combo = 0
		speedup_step = 0.1
	return result_text

# ------------------------------
# FLUJO DE JUEGO
# ------------------------------
func _reset_loop():
	time_accum = 0.0
	intro_ended = false
	sequence_index = 0
	player_move = -1
	result_shown = false
	result_timer = 0.0
	cpu_move = -1
	for lbl in clones:
		lbl.visible = true
		lbl.text = clones[0].text
	var second_hand = hands_group.get_child(1)
	if second_hand is Sprite2D:
		second_hand.frame = original_hand_frame
		second_hand.flip_h = original_hand_flip_h

func _game_over():
	var winner_text = ""
	if PlayerPoints > CPUPoints:
		winner_text = "Player Wins!"
		_animate_head()
		game_round += 1
	else:
		game_over = true
		winner_text = "CPU Wins!"
		hands_group.get_child(0).frame = original_hand_frame
		hands_group.get_child(0).flip_h = true
		hands_group.get_child(1).flip_h = false
		hands_group.get_child(1).frame = original_hand_frame
	for lbl in clones:
		lbl.visible = true
		lbl.text = winner_text
	if game_over:
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://control.tscn")
		return
	for lbl in $RoundLabels.get_children():
		lbl.text = "Round %s" % game_round
	var second_hand = hands_group.get_child(1)
	if second_hand is Sprite2D:
		second_hand.frame = original_hand_frame
		second_hand.flip_h = original_hand_flip_h
	PlayerPoints = 0
	CPUPoints = 0
	for lbl in $PointsLabels.get_children():
		lbl.text = "0 - 0"

# ------------------------------
# ANIMACIONES CABEZA
# ------------------------------
func _animate_head() -> void:
	var tween = create_tween()
	var screen_bottom = DisplayServer.window_get_size().y + 100
	head_start_pos = head_root.position
	tween.tween_property(head_root, "position:y", screen_bottom, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_change_head_texture"))
	tween.tween_callback(func():
		head_root.position = head_start_pos - Vector2(0, 200)
		head_root.rotation_degrees = 0
	)
	tween.tween_property(head_root, "position", head_start_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		var rot_tween = create_tween()
		rot_tween.tween_property(head_root, "rotation_degrees", head_root.rotation_degrees + 360, 0.5)
	)
	await tween.finished

func start_head_shake(intensity := 5.0, speed := 0.05) -> void:
	if shaking: return
	shaking = true
	_shake_head(intensity, speed)

func _shake_head(intensity: float, speed: float) -> void:
	if not shaking:
		head_sprite.position = Vector2.ZERO
		return
	var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	var tween = create_tween()
	tween.tween_property(head_sprite, "position", offset, speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _shake_head(intensity, speed))

func stop_head_shake() -> void:
	shaking = false
	head_sprite.position = Vector2.ZERO

func _change_head_texture() -> void:
	if enemy_textures.size() > 1:
		var new_texture = head_sprite.texture
		while new_texture == head_sprite.texture:
			new_texture = enemy_textures[randi() % enemy_textures.size()]
		head_sprite.texture = new_texture
	elif enemy_textures.size() == 1:
		head_sprite.texture = enemy_textures[0]
