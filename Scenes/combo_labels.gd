extends Label

@onready var labels_group = get_parent()
var colors := [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]

func _ready():
	var num_labels = labels_group.get_child_count()
	for i in range(num_labels):
		var lbl = labels_group.get_child(i)
		if lbl is Label:
			var tween = create_tween().set_loops()
			var base_size = 32
			var offset = i * 0.2
			var target_size = base_size + 6

			tween.tween_property(lbl, "theme_override_font_sizes/font_size", target_size, 0.5 + offset)
			tween.tween_property(lbl, "theme_override_font_sizes/font_size", base_size, 0.5 + offset)

			var color_index = int(float(i) / float(num_labels - 1) * float(colors.size() - 1))
			lbl.modulate = colors[color_index]
