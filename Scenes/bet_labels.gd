extends Label

var time_accum := 0.0
var colors := [Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.BLUE]

func _ready() -> void:
	set_all_text("1")

func _process(delta):
	time_accum += delta

	var labels_group = $".."
	var num_labels = labels_group.get_child_count()
	for i in range(num_labels):
		var lbl = labels_group.get_child(i)
		if lbl.visible:
			lbl.rotation_degrees = 2.0 * sin((time_accum - 0.1*i) * 2.0)

			var color_index = int(float(i) / float(num_labels - 1) * float(colors.size() - 1))
			lbl.modulate = colors[color_index]

func set_all_text(new_text: String) -> void:
	var labels_group = $".."
	for i in range(labels_group.get_child_count()):
		var lbl = labels_group.get_child(i)
		if lbl is Label:
			lbl.text = new_text
