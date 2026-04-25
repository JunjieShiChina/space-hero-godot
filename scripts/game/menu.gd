extends Control

const UnityStage0Data = preload("res://generated/unity_stage0_menu_data.gd")
const TITLE_BASE_COLOR := Color(1.0, 0.56, 0.22, 1.0)
const TITLE_FLASH_COLOR := Color(1.0, 0.92, 0.20, 1.0)
const ITEM_SELECTED_MIN_ALPHA := 0.18
const ITEM_CONFIRM_MIN_ALPHA := 0.04

@onready var items: Array[Node2D] = [
	$MenuItems/NewGame,
	$MenuItems/QuitGame,
]
@onready var title: Node2D = $Title
@onready var selector: Sprite2D = $Selector
@onready var star_layers: Array[TextureRect] = [
	$DimStars,
	$Stars,
	$BrightStars,
]
@onready var hero_ship: Sprite2D = $Ships/HeroShip
@onready var wingmen: Array[Sprite2D] = [
	$Ships/Wingman1,
	$Ships/Wingman2,
]
@onready var drifting_rocks: Array[Sprite2D] = [
	$Rocks/Rock1,
	$Rocks/Rock2,
	$Rocks/Rock3,
	$Rocks/Rock4,
	$Rocks/Rock5,
	$Rocks/Rock6,
	$Rocks/Rock7,
	$Rocks/Rock8,
]

var selected := 0
var orbit_angle := 0.0
var rock_rng := RandomNumberGenerator.new()
var confirm_active := false
var confirm_timer := 0.0
var anim_time := 0.0


func _ready() -> void:
	AudioBus.play_music("menu")
	rock_rng.seed = 240424
	_setup_star_twinkle()
	_update_selection()


func _process(delta: float) -> void:
	anim_time += delta
	_update_title_flash()
	_update_item_flash(delta)
	_update_orbit(delta)
	_update_rocks(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		selected = max(0, selected - 1)
		AudioBus.play_sfx("select")
		_update_selection()
	elif event.is_action_pressed("move_down"):
		selected = min(items.size() - 1, selected + 1)
		AudioBus.play_sfx("select")
		_update_selection()
	elif event.is_action_pressed("ui_accept"):
		if confirm_active:
			return
		if selected == 0:
			_start_confirm_flash()
		else:
			get_tree().quit()


func _update_selection() -> void:
	for index in items.size():
		items[index].modulate = Color(1.0, 1.0, 1.0, 1.0)
	if selected < items.size():
		selector.position = Vector2(items[selected].global_position.x - 47, items[selected].global_position.y + 19)


func _update_title_flash() -> void:
	var flash := (1.0 - cos(anim_time * 2.2)) * 0.5
	title.modulate = TITLE_BASE_COLOR.lerp(TITLE_FLASH_COLOR, flash)


func _update_item_flash(delta: float) -> void:
	if confirm_active:
		confirm_timer -= delta
		var pulse := (1.0 - cos(anim_time * 34.0)) * 0.5
		items[selected].modulate = Color(1.0, 1.0, 1.0, lerp(ITEM_CONFIRM_MIN_ALPHA, 1.0, pulse))
		if confirm_timer <= 0.0:
			SceneFlow.start_new_game()
		return
	for index in items.size():
		if index == selected:
			var pulse := (1.0 - cos(anim_time * 4.0)) * 0.5
			items[index].modulate = Color(1.0, 1.0, 1.0, lerp(ITEM_SELECTED_MIN_ALPHA, 1.0, pulse))
		else:
			items[index].modulate = Color(1.0, 1.0, 1.0, 1.0)


func _start_confirm_flash() -> void:
	confirm_active = true
	confirm_timer = 1.5
	AudioBus.play_sfx("game_start", 0.0)


func _update_orbit(delta: float) -> void:
	orbit_angle -= delta * 2.0
	for index in wingmen.size():
		var angle := orbit_angle + float(index) * TAU / float(wingmen.size())
		wingmen[index].position = hero_ship.position + Vector2(cos(angle) * 58.0, sin(angle) * 78.0)
		wingmen[index].rotation = 0.0


func _update_rocks(delta: float) -> void:
	for rock in drifting_rocks:
		var velocity: Vector2 = rock.get_meta("velocity")
		rock.position += velocity * delta
		rock.rotation += delta * 0.18
		if rock.position.y > 820:
			rock.position = Vector2(rock_rng.randf_range(40.0, 1240.0), rock_rng.randf_range(-160.0, -60.0))
			rock.set_meta("velocity", Vector2(rock_rng.randf_range(-10.0, 10.0), rock_rng.randf_range(45.0, 80.0)))


func _setup_star_twinkle() -> void:
	var layer_data := [
		[0.0, 0.75, 0.9],
		[37.0, 1.0, 1.2],
		[91.0, 1.45, 1.85],
	]
	for index in star_layers.size():
		star_layers[index].material = _make_star_material(layer_data[index][0], layer_data[index][1], layer_data[index][2])


func _make_star_material(layer_seed: float, alpha_scale: float, brightness_scale: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float layer_seed = 0.0;
uniform float alpha_scale = 1.0;
uniform float brightness_scale = 1.0;

float hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	vec2 cell = floor(UV * vec2(128.0, 72.0) + vec2(layer_seed, layer_seed * 0.37));
	float phase = hash(cell) * 6.2831853;
	float speed = mix(0.55, 2.2, hash(cell + vec2(19.0, 73.0)));
	float wave = sin(TIME * speed + phase);
	float spark = smoothstep(0.03, 0.9, color.a);
	float twinkle = mix(0.08, 2.2, (wave + 1.0) * 0.5);
	vec3 bright = color.rgb * brightness_scale * mix(0.65, 2.2, (wave + 1.0) * 0.5);
	COLOR = vec4(bright, color.a * alpha_scale * mix(1.0, twinkle, spark));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("layer_seed", layer_seed)
	material.set_shader_parameter("alpha_scale", alpha_scale)
	material.set_shader_parameter("brightness_scale", brightness_scale)
	return material
