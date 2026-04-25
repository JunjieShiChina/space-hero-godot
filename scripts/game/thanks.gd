extends Control

const StarfieldScene := preload("res://scenes/components/starfield_particles.tscn")


func _ready() -> void:
	AudioBus.play_music("success")
	_build()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		SceneFlow.start_new_game()
	elif event.is_action_pressed("pause"):
		SceneFlow.go_main_menu()

func _build() -> void:
	_add_starfield_background()
	var title := _label("THANKS FOR PLAYING", DisplaySettings.scale_font_size(78), DisplaySettings.to_current(Vector2(0, 51)), Color(0.85, 1.0, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(105))
	add_child(title)
	var y := 195
	for key in ["meteor", "ship", "ep2", "rotation_ep", "meteor_enemy", "small_boss", "boss1", "boss2", "boss3", "coin1", "coin2", "coin3"]:
		var label := _label("%-16s %d" % [key.to_upper(), GameData.stats.get(key, 0)], DisplaySettings.scale_font_size(39), DisplaySettings.to_current(Vector2(645, y)), Color(0.75, 0.95, 1.0))
		add_child(label)
		y += 57
	var hint := _label("ENTER: New Run    ESC: Main Menu", DisplaySettings.scale_font_size(36), DisplaySettings.to_current(Vector2(0, 975)), Color.WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(60))
	add_child(hint)


func _add_starfield_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	add_child(bg)
	var starfield := StarfieldScene.instantiate()
	starfield.name = "Starfield"
	add_child(starfield)


func _label(text_value: String, size_value: int, pos: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label
