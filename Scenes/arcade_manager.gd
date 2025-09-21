extends Control

@onready var labels_group = $GameLabels
@onready var hands_group = $Hands
@onready var head_root = $Heads
@onready var head_sprite = $Heads/Head

@export var colors: Array = [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]
@export var display_time: float = 4
@export var gameinfo_display_time: float = 1.0
@export var speedup_step: float = 0.05
@onready var color_rect = $ColorRect

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
var game_round: int = 1
var is_boss_round: bool = false
var invalid_player_move: int = -1
var invalid_cpu_move: int = -1
var point_diff_towin: int = 2

var head_start_pos: Vector2
var hand_start_pos: Vector2
var head_start_rot: float = 0
var enemy_textures: Array = []

var shaking := false

# ------------------------------
# SETUP
# ------------------------------
func _ready():
	var tween = create_tween()
	tween.tween_property($ColorRect2, "color:a", 0.0, 1)
	$Smokes/SmokePlayer.seek(0.0, true)
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
	_update_gradient_color()

func _update_gradient_color():
	var t = clamp(gameinfo_display_time / 1.0, 0, 1) 
	var blue = Color(100/255.0, 127/255.0, 188/255.0)
	var red = Color(180/255.0, 40/255.0, 40/255.0)
	color_rect.color = blue.lerp(red, 1.0 - t)

func _update_label_wobble():
	for i in clones.size():
		if clones[i].visible:
			clones[i].rotation_degrees = 4.0 * sin((time_accum - i * 0.1) * 2.0)

func _check_player_input():
	if Input.is_action_just_pressed("ui_left"): player_move = 0
	elif Input.is_action_just_pressed("ui_up"): player_move = 1
	elif Input.is_action_just_pressed("ui_right"): player_move = 2
	
	if player_move == invalid_player_move: player_move = -1

func _handle_intro():
	if not intro_ended and time_accum >= (display_time):
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
			if abs(PlayerPoints - CPUPoints) >= point_diff_towin:
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
	else: 
		$Smokes/SmokePlayer.seek(0.0, true)
		$Smokes/SmokePlayer.stop()
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
	_animate_key()
	invalid_player_move = player_move
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
		if is_boss_round and abs(PlayerPoints - CPUPoints) < point_diff_towin:
			_animate_hand()
		is_boss_round = game_round % 5 == 0

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
		var value: int = -1
		if FileAccess.file_exists("user://score.dat"):
			var f = FileAccess.open("user://score.dat", FileAccess.READ)
			var flag = f.get_8()
			if flag == 1:
				value = f.get_32()
			f.close()

		if value == -1 or game_round > value:
			var f = FileAccess.open("user://score.dat", FileAccess.WRITE)
			f.store_8(1)
			f.store_32(game_round)
			f.close()

		var tween = create_tween()
		tween.tween_property($ColorRect2, "color:a", 1, 3)
		tween.tween_callback(Callable(self, "_change_scene_menu"))

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

func _change_scene_menu():
	get_tree().change_scene_to_file("res://control.tscn")

func _animate_key() -> void:
	if invalid_player_move == -1 or not is_boss_round:
		return
	
	var key = $Inputs.get_child(invalid_player_move)
	var start_pos = key.position
	key.position = start_pos + Vector2(0, 100)
	key.visible = true
	
	var tween = create_tween()
	tween.tween_property(key, "position", start_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_hand() -> void:
	if invalid_player_move == -1: return
	var hand = hands_group.get_child(0) as Node2D
	var key_top = $Inputs.get_child(invalid_player_move).global_position - Vector2(0, 40)
	var hand_start_pos = hand.position

	hand.frame = 13

	var tween = create_tween()
	tween.tween_property(hand, "position", key_top, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		$Inputs.get_child(invalid_player_move).visible = false
		$Particles.get_child(invalid_player_move).emitting = true
		$Inputs/AudioStreamPlayer2D.play()
	)
	tween.tween_property(hand, "position", hand_start_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		hand.frame = 12
	)

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
		
		if is_boss_round == false: return
		$Heads/Head/AudioStreamPlayer2D.play()
		var bounce_tween = create_tween()
		for i in range(6):
			bounce_tween.tween_property(head_root, "position:y", head_start_pos.y - 50, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.tween_property(head_root, "position:y", head_start_pos.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
