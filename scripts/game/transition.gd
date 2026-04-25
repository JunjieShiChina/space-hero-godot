extends Control

func _ready() -> void:
	AudioBus.play_music("stage")
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/Stars.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_TILE
	add_child(bg)
	var label := Label.new()
	label.text = "STAGE %d" % (GameData.current_stage_index + 1)
	label.size = Vector2(1280, 160)
	label.position = Vector2(0, 260)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 76)
	label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	add_child(label)
	await get_tree().create_timer(2.0).timeout
	SceneFlow.continue_after_transition()
