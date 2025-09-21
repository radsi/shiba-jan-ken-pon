extends Node2D

@onready var labels_group = $GameLabels
@onready var hands_group = $Hands
@onready var head_sprite = $Heads/Head

@export var colors: Array = [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]
@export var display_time: float = 3
@export var result_display_time: float = 1.0
@export var speedup_step: float = 0.05

var clones: Array = []
var time_accum: float = 0.0
var intro_ended = false
var CPUPoints = 0
var PlayerPoints = 0
var sequence = [["Jan", 1.0], ["Ken", 1.0], ["Pon", 1.0]]
var sequence_index = 0

var player_move: int = -1
var result_shown = false
var result_timer: float = 0.0
var cpu_move: int = -1
var original_hand_frame: int
var original_hand_flip_h: bool
var game_over = false

var head_start_pos: Vector2
var head_start_rot: float
var enemy_textures: Array = []

func _ready():
	for lbl in labels_group.get_children():
		if lbl is Label:
			clones.append(lbl)
	for i in range(clones.size()):
		var color_index = int(float(i) / float(clones.size() - 1) * float(colors.size() - 1))
		clones[i].modulate = colors[color_index]
		clones[i].text = clones[0].text
		clones[i].visible = true
		clones[i].rotation_degrees = 0

	var second_hand = hands_group.get_child(1)
	if second_hand is Sprite2D:
		original_hand_frame = second_hand.frame
		original_hand_flip_h = second_hand.flip_h

	head_start_pos = head_sprite.position
	head_start_rot = head_sprite.rotation_degrees

	var dir = "res://Enemies/"
	var da = DirAccess.open(dir)
	if da:
		da.list_dir_begin()
		while true:
			var f = da.get_next()
			if f == "":
				break
			if f.ends_with(".png"):
				enemy_textures.append(load(dir + f))
		da.list_dir_end()

func _process(delta):
	time_accum += delta

	for i in range(clones.size()):
		var lbl = clones[i]
		if lbl.visible:
			var phase_offset = i * 0.1
			lbl.rotation_degrees = 4.0 * sin((time_accum - phase_offset) * 2.0)

	if game_over:
		return

	if Input.is_action_just_pressed("ui_left"):
		player_move = 0
	elif Input.is_action_just_pressed("ui_up"):
		player_move = 1
	elif Input.is_action_just_pressed("ui_right"):
		player_move = 2

	if not intro_ended and time_accum >= display_time:
		intro_ended = true
		for lbl in clones:
			lbl.visible = false
		for hand in hands_group.get_children():
			if hand is Sprite2D:
				hand.frame = 12
		time_accum = 0.0

	if intro_ended and sequence_index < sequence.size():
		var text = sequence[sequence_index][0]
		var duration = sequence[sequence_index][1]

		for lbl in clones:
			lbl.visible = true
			lbl.text = text

		if time_accum >= duration:
			time_accum = 0.0
			sequence_index += 1

	if intro_ended and sequence_index >= sequence.size() and not result_shown:
		for lbl in clones:
			lbl.visible = false

		cpu_move = randi() % 3
		var second_hand = hands_group.get_child(1)
		if second_hand is Sprite2D:
			match cpu_move:
				0: second_hand.frame = 13;
