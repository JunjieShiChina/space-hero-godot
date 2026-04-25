extends Control

const StarfieldScene := preload("res://scenes/components/starfield_particles.tscn")

var navigation_requested := false


func _ready() -> void:
	AudioBus.play_music("game_over")
	_build()

func _input(event: InputEvent) -> void:
	if navigation_requested:
		return
	if event.is_action_pressed("ui_accept"):
		navigation_requested = true
		SceneFlow.start_new_game()
	elif event.is_action_pressed("pause"):
		navigation_requested = true
		SceneFlow.go_main_menu()

func _build() -> void:
	_add_starfield_background()
	var title := _label("GAME OVER", DisplaySettings.scale_font_size(117), DisplaySettings.to_current(Vector2(0, 315)), Color(1, 0.35, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(150))
	add_child(title)
	var hint := _label("ENTER: Restart    ESC: Main Menu", DisplaySettings.scale_font_size(45), DisplaySettings.to_current(Vector2(0, 630)), Color(0.85, 0.95, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(90))
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
