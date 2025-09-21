extends Node

var money := 100
var save_path := "user://player_data.cfg"

func _ready() -> void:
	load_money()

func save_money() -> void:
	var config = ConfigFile.new()
	config.set_value("player", "money", money)
	config.save(save_path)

func load_money() -> void:
	var config = ConfigFile.new()
	var err = config.load(save_path)
	if err == OK:
		money = config.get_value("player", "money", 0)
