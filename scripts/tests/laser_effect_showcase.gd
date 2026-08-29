extends Control

const DEMO_BEAM_SCENE := preload("res://scenes/tests/laser_effect_demo_beam.tscn")
const STARFIELD_SCENE := preload("res://scenes/components/starfield_particles.tscn")
const STYLE_GDQUEST := 0
const STYLE_GOLDTIME := 1
const STYLE_BLASTER_GLOW := 2
const STYLE_LENROW := 3
const STYLE_LUMENFRUIT := 4

var _beams: Array[Node] = []


func _ready() -> void:
	_create_background()
	_create_showcase_rows()
	_create_footer()
	await get_tree().create_timer(0.35).timeout
	_trigger_all()
	_auto_cycle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_U:
		_trigger_all()
		accept_event()


func _create_background() -> void:
	var background := ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(background)

	var vignette := ColorRect.new()
	vignette.anchor_right = 1.0
	vignette.anchor_bottom = 1.0
	vignette.color = Color(0.04, 0.02, 0.08, 0.38)
	add_child(vignette)

	var starfield := STARFIELD_SCENE.instantiate()
	add_child(starfield)

	var header := Label.new()
	header.position = Vector2(88.0, 52.0)
	header.size = Vector2(980.0, 42.0)
	header.text = "Laser Effect Showcase"
	header.add_theme_font_size_override("font_size", 28)
	header.modulate = Color(0.96, 0.96, 1.0, 1.0)
	add_child(header)

	var subheader := Label.new()
	subheader.position = Vector2(90.0, 96.0)
	subheader.size = Vector2(1600.0, 32.0)
	subheader.text = "Press U to fire all five public-reference beams. This scene is for side-by-side structure and motion comparison."
	subheader.add_theme_font_size_override("font_size", 17)
	subheader.modulate = Color(0.76, 0.82, 0.98, 0.88)
	add_child(subheader)


func _create_showcase_rows() -> void:
	var rows := [
		{
			"title": "1. GDQuest 2D Laser",
			"subtitle": "RayCast2D beam with line growth, muzzle burst, hit burst, and beam particles",
			"style": STYLE_GDQUEST,
		},
		{
			"title": "2. Goldtime64 Laser Beam",
			"subtitle": "Single shader strip: flicker, sine wave motion, and center-core falloff",
			"style": STYLE_GOLDTIME,
		},
		{
			"title": "3. Calfur Laser Blaster Glow",
			"subtitle": "Glow-mask blaster strip with hot core and wider green halo",
			"style": STYLE_BLASTER_GLOW,
		},
		{
			"title": "4. Lenrow 2D Lightning Beam",
			"subtitle": "Noise-driven lightning sheet with layered thin strands and blue-white ramp",
			"style": STYLE_LENROW,
		},
		{
			"title": "5. Lumenfruit Arc Plasma",
			"subtitle": "Gradient + noise plasma strip with smoother magenta arc displacement",
			"style": STYLE_LUMENFRUIT,
		},
	]

	var start_y := 182.0
	for index in range(rows.size()):
		var row := rows[index] as Dictionary
		var y := start_y + index * 162.0
		_create_row_backplate(y)
		_create_row_labels(row["title"], row["subtitle"], y)
		var beam := DEMO_BEAM_SCENE.instantiate()
		beam.position = Vector2(620.0, y + 34.0)
		beam.style = int(row["style"])
		beam.beam_length = 1080.0
		beam.beam_width = 14.0 if index == 1 else 18.0
		beam.fire_duration = 2.4
		add_child(beam)
		_beams.append(beam)


func _create_row_backplate(y: float) -> void:
	var plate := ColorRect.new()
	plate.position = Vector2(64.0, y - 28.0)
	plate.size = Vector2(1792.0, 112.0)
	plate.color = Color(0.05, 0.07, 0.13, 0.44)
	add_child(plate)

	var separator := ColorRect.new()
	separator.position = Vector2(604.0, y - 18.0)
	separator.size = Vector2(2.0, 92.0)
	separator.color = Color(0.22, 0.28, 0.40, 0.62)
	add_child(separator)


func _create_row_labels(title: String, subtitle: String, y: float) -> void:
	var title_label := Label.new()
	title_label.position = Vector2(92.0, y - 6.0)
	title_label.size = Vector2(460.0, 28.0)
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.modulate = Color(0.97, 0.98, 1.0, 1.0)
	add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.position = Vector2(92.0, y + 24.0)
	subtitle_label.size = Vector2(500.0, 40.0)
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.modulate = Color(0.73, 0.79, 0.94, 0.86)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(subtitle_label)


func _create_footer() -> void:
	var footer := Label.new()
	footer.position = Vector2(88.0, 1018.0)
	footer.size = Vector2(1700.0, 26.0)
	footer.text = "Use this scene to compare reference identity first: beam silhouette, growth behavior, surface motion, and endpoint feedback."
	footer.add_theme_font_size_override("font_size", 15)
	footer.modulate = Color(0.68, 0.74, 0.88, 0.72)
	add_child(footer)


func _trigger_all() -> void:
	for beam in _beams:
		beam.trigger_fire()


func _auto_cycle() -> void:
	while is_inside_tree():
		await get_tree().create_timer(3.2).timeout
		if not is_inside_tree():
			return
		_trigger_all()
