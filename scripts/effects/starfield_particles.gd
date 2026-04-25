extends Node2D

const BOX_MARGIN := 24.0
const LAYER_SETTINGS := {
	"FarStars": {
		"amount": 920,
		"lifetime": 9.0,
		"speed_scale": 0.72,
		"velocity_min": 2.0,
		"velocity_max": 7.0,
		"spread": 26.0,
		"scale_min": 1.1,
		"scale_max": 2.0,
		"color": Color(0.54, 0.66, 0.95, 0.40),
		"seed": 1207,
		"twinkle": 0.58,
	},
	"MidStars": {
		"amount": 420,
		"lifetime": 7.6,
		"speed_scale": 0.82,
		"velocity_min": 4.0,
		"velocity_max": 12.0,
		"spread": 20.0,
		"scale_min": 1.6,
		"scale_max": 3.1,
		"color": Color(0.72, 0.84, 1.0, 0.62),
		"seed": 4913,
		"twinkle": 0.78,
	},
	"BrightStars": {
		"amount": 150,
		"lifetime": 6.4,
		"speed_scale": 0.86,
		"velocity_min": 5.0,
		"velocity_max": 15.0,
		"spread": 16.0,
		"scale_min": 2.0,
		"scale_max": 4.8,
		"color": Color(0.95, 0.97, 1.0, 0.92),
		"seed": 8021,
		"twinkle": 1.0,
	},
	"WarmSparks": {
		"amount": 52,
		"lifetime": 8.8,
		"speed_scale": 0.64,
		"velocity_min": 1.0,
		"velocity_max": 6.0,
		"spread": 34.0,
		"scale_min": 2.2,
		"scale_max": 4.8,
		"color": Color(1.0, 0.88, 0.58, 0.56),
		"seed": 9511,
		"twinkle": 0.88,
	},
}

@onready var particle_layers: Array[GPUParticles2D] = [
	$FarStars,
	$MidStars,
	$BrightStars,
	$WarmSparks,
]

var _last_view_size := Vector2.ZERO


func _ready() -> void:
	_configure_layers()
	_resize_layers(true)
	if not DisplaySettings.changed.is_connected(_on_display_settings_changed):
		DisplaySettings.changed.connect(_on_display_settings_changed)


func _process(_delta: float) -> void:
	var view_size := _view_size()
	if not view_size.is_equal_approx(_last_view_size):
		_resize_layers(false)


func _on_display_settings_changed() -> void:
	_resize_layers(false)


func _configure_layers() -> void:
	for particles in particle_layers:
		var settings: Dictionary = LAYER_SETTINGS[particles.name]
		particles.amount = int(settings["amount"])
		particles.lifetime = float(settings["lifetime"])
		particles.preprocess = particles.lifetime
		particles.randomness = 0.92
		particles.explosiveness = 0.0
		particles.speed_scale = float(settings["speed_scale"])
		particles.fixed_fps = 30
		particles.fract_delta = true
		particles.interpolate = true
		particles.use_fixed_seed = true
		particles.seed = int(settings["seed"])
		particles.texture = null
		particles.material = _make_canvas_material()
		particles.process_material = _make_process_material(settings)
		particles.emitting = true


func _resize_layers(force_restart: bool) -> void:
	var view_size := _view_size()
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return
	_last_view_size = view_size
	position = view_size * 0.5
	for particles in particle_layers:
		var margin := DisplaySettings.scale_value(BOX_MARGIN)
		var material := particles.process_material as ParticleProcessMaterial
		if material == null:
			continue
		material.emission_box_extents = Vector3(view_size.x * 0.5 + margin, view_size.y * 0.5 + margin, 1.0)
		particles.visibility_rect = Rect2(
			Vector2(-view_size.x * 0.5 - margin, -view_size.y * 0.5 - margin),
			view_size + Vector2.ONE * margin * 2.0
		)
		if force_restart:
			particles.restart()


func _view_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		return viewport_size
	return DisplaySettings.logical_size()


func _make_canvas_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func _make_process_material(settings: Dictionary) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(960.0, 540.0, 1.0)
	material.direction = Vector3(0.06, 1.0, 0.0).normalized()
	material.spread = float(settings["spread"])
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = float(settings["velocity_min"])
	material.initial_velocity_max = float(settings["velocity_max"])
	material.scale_min = float(settings["scale_min"])
	material.scale_max = float(settings["scale_max"])
	material.color = settings["color"]
	material.color_ramp = _make_color_ramp(settings["color"], float(settings["twinkle"]))
	material.scale_curve = _make_scale_curve(float(settings["twinkle"]))
	material.angular_velocity_min = -12.0
	material.angular_velocity_max = 12.0
	material.lifetime_randomness = 0.34
	material.particle_flag_disable_z = true
	return material


func _make_color_ramp(base_color: Color, twinkle: float) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.12))
	gradient.set_color(1, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.10))
	gradient.add_point(0.12, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.38 * twinkle))
	gradient.add_point(0.31, Color(1.0, 1.0, 1.0, base_color.a * 0.92 * twinkle))
	gradient.add_point(0.50, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.22))
	gradient.add_point(0.70, Color(1.0, 1.0, 1.0, base_color.a * twinkle))
	gradient.add_point(0.88, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.34 * twinkle))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _make_scale_curve(twinkle: float) -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.00, 0.28))
	curve.add_point(Vector2(0.14, 0.52 * twinkle))
	curve.add_point(Vector2(0.31, 1.00 * twinkle))
	curve.add_point(Vector2(0.50, 0.34))
	curve.add_point(Vector2(0.70, 0.86 * twinkle))
	curve.add_point(Vector2(0.88, 0.38 * twinkle))
	curve.add_point(Vector2(1.00, 0.24))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture
