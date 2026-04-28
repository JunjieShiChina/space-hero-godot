extends Node2D
class_name BackgroundAsteroids

@export var extra_multiplier := 3
@export var rng_seed := 240424
@export_range(0.5, 4.0, 0.05) var fall_speed_multiplier := 1.55

const ROCK_INITIAL_LAYERS := [0, 1, 2, 1, 0, 2, 1, 2]
const ROCK_LAYER_DATA := [
	{
		"scale_min": 0.25,
		"scale_max": 0.45,
		"speed_min": 28.0,
		"speed_max": 54.0,
		"drift_min": -10.0,
		"drift_max": 10.0,
		"rotation_min": -0.18,
		"rotation_max": 0.18,
		"modulate": Color(0.09, 0.08, 0.11, 0.58),
		"z_index": 0,
		"spawn_y_min": -420.0,
		"spawn_y_max": -80.0,
		"spawn_margin": 240.0,
		"despawn_margin": 300.0,
	},
	{
		"scale_min": 0.5,
		"scale_max": 0.9,
		"speed_min": 48.0,
		"speed_max": 86.0,
		"drift_min": -18.0,
		"drift_max": 18.0,
		"rotation_min": -0.32,
		"rotation_max": 0.32,
		"modulate": Color(0.07, 0.06, 0.085, 0.74),
		"z_index": 1,
		"spawn_y_min": -520.0,
		"spawn_y_max": -100.0,
		"spawn_margin": 280.0,
		"despawn_margin": 340.0,
	},
	{
		"scale_min": 0.95,
		"scale_max": 1.7,
		"speed_min": 72.0,
		"speed_max": 125.0,
		"drift_min": -26.0,
		"drift_max": 26.0,
		"rotation_min": -0.46,
		"rotation_max": 0.46,
		"modulate": Color(0.05, 0.045, 0.065, 0.9),
		"z_index": 2,
		"spawn_y_min": -640.0,
		"spawn_y_max": -130.0,
		"spawn_margin": 330.0,
		"despawn_margin": 410.0,
	},
]

var _rocks: Array[Sprite2D] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = rng_seed
	_collect_rocks()
	_ensure_rock_count()
	_setup_rocks()
	if not DisplaySettings.changed.is_connected(_reset_layout):
		DisplaySettings.changed.connect(_reset_layout)


func _process(delta: float) -> void:
	for rock in _rocks:
		var velocity: Vector2 = rock.get_meta("velocity", Vector2.ZERO)
		rock.position += velocity * delta
		rock.rotation += delta * float(rock.get_meta("rotation_speed", 0.0))
		if rock.position.y > DisplaySettings.logical_size().y + float(rock.get_meta("despawn_margin", 0.0)):
			_apply_rock_layer(rock, _pick_rock_layer(), true)


func _collect_rocks() -> void:
	_rocks.clear()
	for child in get_children():
		if child is Sprite2D:
			_rocks.append(child)


func _ensure_rock_count() -> void:
	var template_count := _rocks.size()
	if template_count == 0:
		return
	var target_count := template_count * (extra_multiplier + 1)
	while _rocks.size() < target_count:
		var template := _rocks[_rocks.size() % template_count]
		var rock := template.duplicate() as Sprite2D
		rock.name = "Rock%d" % (_rocks.size() + 1)
		add_child(rock)
		_rocks.append(rock)


func _setup_rocks() -> void:
	for index in _rocks.size():
		var layer_index := int(ROCK_INITIAL_LAYERS[index % ROCK_INITIAL_LAYERS.size()])
		_apply_rock_layer(_rocks[index], layer_index, false)


func _reset_layout() -> void:
	_setup_rocks()


func _pick_rock_layer() -> int:
	var roll := _rng.randf()
	if roll < 0.24:
		return 0
	if roll < 0.6:
		return 1
	return 2


func _apply_rock_layer(rock: Sprite2D, layer_index: int, respawn: bool) -> void:
	var layer: Dictionary = ROCK_LAYER_DATA[layer_index]
	var scale_value := _rng.randf_range(float(layer["scale_min"]), float(layer["scale_max"]))
	var velocity := Vector2(
		_rng.randf_range(float(layer["drift_min"]), float(layer["drift_max"])),
		_rng.randf_range(float(layer["speed_min"]), float(layer["speed_max"]))
	)
	velocity.y *= fall_speed_multiplier
	rock.scale = Vector2.ONE * scale_value * DisplaySettings.scale_factor()
	rock.modulate = layer["modulate"]
	rock.z_index = int(layer["z_index"])
	rock.set_meta("velocity", DisplaySettings.to_current(velocity))
	rock.set_meta("rotation_speed", _rng.randf_range(float(layer["rotation_min"]), float(layer["rotation_max"])))
	rock.set_meta("despawn_margin", DisplaySettings.scale_value(float(layer["despawn_margin"])))
	rock.set_meta("depth_layer", layer_index)

	var spawn_margin := DisplaySettings.scale_value(float(layer["spawn_margin"]))
	var viewport_size := DisplaySettings.logical_size()
	if respawn:
		rock.position = Vector2(
			_rng.randf_range(-spawn_margin, viewport_size.x + spawn_margin),
			_rng.randf_range(DisplaySettings.scale_value(float(layer["spawn_y_min"])), DisplaySettings.scale_value(float(layer["spawn_y_max"])))
		)
	else:
		var despawn_margin := DisplaySettings.scale_value(float(layer["despawn_margin"]))
		rock.position = Vector2(
			_rng.randf_range(-spawn_margin, viewport_size.x + spawn_margin),
			_rng.randf_range(-despawn_margin, viewport_size.y + despawn_margin * 0.35)
		)
