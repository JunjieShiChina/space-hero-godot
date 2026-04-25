extends Control

func _ready() -> void:
	AudioBus.play_music("game_over")
	_build()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		SceneFlow.start_new_game()
	elif event.is_action_pressed("pause"):
		SceneFlow.go_main_menu()

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/Background_02.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	var title := _label("GAME OVER", 78, Vector2(0, 210), Color(1, 0.35, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280, 100)
	add_child(title)
	var hint := _label("ENTER: Restart    ESC: Main Menu", 30, Vector2(0, 420), Color(0.85, 0.95, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1280, 60)
	add_child(hint)

func _label(text_value: String, size_value: int, pos: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label
