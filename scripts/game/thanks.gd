extends Control

func _ready() -> void:
	AudioBus.play_music("success")
	_build()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		SceneFlow.start_new_game()
	elif event.is_action_pressed("pause"):
		SceneFlow.go_main_menu()

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/Background_03.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	var title := _label("THANKS FOR PLAYING", 52, Vector2(0, 34), Color(0.85, 1.0, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280, 70)
	add_child(title)
	var y := 130
	for key in ["meteor", "ship", "ep2", "rotation_ep", "meteor_enemy", "small_boss", "boss1", "boss2", "boss3", "coin1", "coin2", "coin3"]:
		var label := _label("%-16s %d" % [key.to_upper(), GameData.stats.get(key, 0)], 26, Vector2(430, y), Color(0.75, 0.95, 1.0))
		add_child(label)
		y += 38
	var hint := _label("ENTER: New Run    ESC: Main Menu", 24, Vector2(0, 650), Color.WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280, 40)
	add_child(hint)

func _label(text_value: String, size_value: int, pos: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label
