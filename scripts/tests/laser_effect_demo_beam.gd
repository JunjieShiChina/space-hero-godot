extends Node2D

class_name LaserEffectDemoBeam

enum LaserStyle {
	GDQUEST_RAYCAST,
	GOLDTIME_LASER_BEAM,
	CALFUR_BLASTER_GLOW,
	LENROW_LIGHTNING_BEAM,
	LUMENFRUIT_ARC_PLASMA,
}

@export var style := LaserStyle.GDQUEST_RAYCAST
@export var beam_length := 1050.0
@export var beam_width := 18.0
@export var fire_duration := 1.5
@export var auto_fire_on_ready := false

var _time := 0.0
var _phase := 0.0
var _is_firing := false
var _line_texture: GradientTexture2D
var _particle_texture: ImageTexture
var _noise_texture_a: NoiseTexture2D
var _noise_texture_b: NoiseTexture2D
var _vertical_gradient: GradientTexture1D

@onready var _back_line: Line2D = $BackLine
@onready var _mid_line: Line2D = $MidLine
@onready var _core_line: Line2D = $CoreLine
@onready var _detail_line: Line2D = $DetailLine
@onready var _beam_rect: ColorRect = $BeamRect
@onready var _beam_core_rect: ColorRect = $BeamRect/BeamCoreRect
@onready var _beam_particles: GPUParticles2D = $BeamParticles
@onready var _muzzle_particles: GPUParticles2D = $MuzzleParticles
@onready var _impact_particles: GPUParticles2D = $ImpactParticles


func _ready() -> void:
	_line_texture = _make_line_texture()
	_particle_texture = _make_soft_particle_texture()
	_noise_texture_a = _make_noise_texture(21)
	_noise_texture_b = _make_noise_texture(77)
	_vertical_gradient = _make_vertical_gradient()
	_prepare_shared_nodes()
	_apply_visibility(false)
	if auto_fire_on_ready:
		trigger_fire()


func _process(delta: float) -> void:
	_phase += delta
	if not _is_firing:
		return
	_time += delta
	var progress := clampf(_time / maxf(fire_duration, 0.001), 0.0, 1.0)
	match style:
		LaserStyle.GDQUEST_RAYCAST:
			_update_gdquest(progress)
		LaserStyle.GOLDTIME_LASER_BEAM:
			_update_goldtime(progress)
		LaserStyle.CALFUR_BLASTER_GLOW:
			_update_blaster_glow(progress)
		LaserStyle.LENROW_LIGHTNING_BEAM:
			_update_lenrow_lightning(progress)
		LaserStyle.LUMENFRUIT_ARC_PLASMA:
			_update_lumenfruit_arc(progress)
	if _time >= fire_duration:
		_stop_fire()


func trigger_fire() -> void:
	_is_firing = true
	_time = 0.0
	_prepare_shared_nodes()
	_apply_visibility(true)
	_restart_particles()
	match style:
		LaserStyle.GDQUEST_RAYCAST:
			_apply_gdquest_setup()
		LaserStyle.GOLDTIME_LASER_BEAM:
			_apply_goldtime_setup()
		LaserStyle.CALFUR_BLASTER_GLOW:
			_apply_blaster_glow_setup()
		LaserStyle.LENROW_LIGHTNING_BEAM:
			_apply_lenrow_setup()
		LaserStyle.LUMENFRUIT_ARC_PLASMA:
			_apply_lumenfruit_setup()


func _stop_fire() -> void:
	_is_firing = false
	_apply_visibility(false)


func _prepare_shared_nodes() -> void:
	for line in [_back_line, _mid_line, _core_line, _detail_line]:
		line.visible = false
		line.texture = _line_texture
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.round_precision = 16
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(beam_length, 0.0)])
		line.material = null
		line.gradient = null
	_beam_rect.visible = false
	_beam_rect.position = Vector2.ZERO
	_beam_rect.size = Vector2(beam_length, beam_width * 2.0)
	_beam_rect.pivot_offset = Vector2(0.0, _beam_rect.size.y * 0.5)
	_beam_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beam_rect.material = null
	_beam_rect.modulate = Color.WHITE
	_beam_rect.color = Color.WHITE
	_beam_core_rect.position = Vector2.ZERO
	_beam_core_rect.size = _beam_rect.size
	_beam_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beam_core_rect.visible = false
	_beam_core_rect.material = null
	_beam_core_rect.modulate = Color.WHITE
	_beam_core_rect.color = Color.WHITE
	for particles in [_beam_particles, _muzzle_particles, _impact_particles]:
		particles.texture = _particle_texture
		particles.material = _additive_material()
		particles.local_coords = true
		particles.fixed_fps = 30
		particles.fract_delta = true
	_beam_particles.position = Vector2(beam_length * 0.5, 0.0)
	_beam_particles.visibility_rect = Rect2(
		Vector2(-beam_length * 0.55, -beam_width * 18.0),
		Vector2(beam_length * 1.1, beam_width * 36.0)
	)
	_muzzle_particles.position = Vector2.ZERO
	_muzzle_particles.visibility_rect = Rect2(
		Vector2(-beam_width * 12.0, -beam_width * 12.0),
		Vector2.ONE * beam_width * 24.0
	)
	_impact_particles.position = Vector2(beam_length, 0.0)
	_impact_particles.visibility_rect = Rect2(
		Vector2(-beam_width * 12.0, -beam_width * 12.0),
		Vector2.ONE * beam_width * 24.0
	)


func _apply_visibility(is_visible: bool) -> void:
	visible = is_visible
	_beam_rect.visible = is_visible and _beam_rect.visible
	for node in [_beam_particles, _muzzle_particles, _impact_particles]:
		node.visible = is_visible and node.visible
		node.emitting = is_visible and node.emitting


func _apply_gdquest_setup() -> void:
	_beam_rect.visible = false
	_beam_core_rect.visible = false
	for line in [_back_line, _mid_line, _core_line]:
		line.visible = true
	_detail_line.visible = false
	_set_straight_points(40.0)
	_apply_particle_set(
		Color(0.50, 1.0, 1.0, 0.70),
		Color(0.82, 1.0, 1.0, 0.94),
		Color(0.82, 1.0, 1.0, 0.94),
		72,
		44,
		78
	)
	_beam_particles.visible = true
	_muzzle_particles.visible = true
	_impact_particles.visible = true


func _apply_goldtime_setup() -> void:
	_show_only_rects()
	_beam_rect.visible = true
	_beam_core_rect.visible = false
	_beam_rect.position = Vector2(0.0, -beam_width * 0.42)
	_beam_rect.size = Vector2(beam_length, beam_width * 0.84)
	_beam_rect.material = _shader_material(
		_goldtime_shader(),
		{
			"laser_color": Color(1.0, 0.14, 0.08, 1.0),
			"flicker_speed": 5.0,
			"flicker_strength": 2.0,
			"wave_strength": 0.10,
			"core_power": 1.0,
		}
	)
	_beam_particles.visible = false
	_muzzle_particles.visible = false
	_impact_particles.visible = false


func _apply_blaster_glow_setup() -> void:
	_show_only_lines()
	_mid_line.visible = true
	_mid_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	_mid_line.width = 20.0
	_mid_line.default_color = Color8(0x25, 0x87, 0x22)
	_mid_line.material = _shader_material(
		_blaster_glow_shader(),
		{
			"glow_intensity": 7.0,
			"core_width": 0.60,
			"core_length": 1.0,
		}
	)
	_beam_particles.visible = false
	_muzzle_particles.visible = false
	_impact_particles.visible = false


func _apply_lenrow_setup() -> void:
	_show_only_rects()
	_beam_rect.visible = true
	_beam_core_rect.visible = true
	_beam_rect.position = Vector2(0.0, -beam_width * 1.16)
	_beam_rect.size = Vector2(beam_length, beam_width * 2.32)
	var material := _shader_material(
		_lenrow_shader(),
		{
			"use_color_gradient": true,
			"color_effect_mod": 0.42,
			"intensive": 0.62,
			"lightning_thin": 2.7,
			"number_lightning": 6,
			"speed": 1.2,
			"position": 0.5,
		}
	)
	material.set_shader_parameter("lightning_noise", _noise_texture_a)
	material.set_shader_parameter("background_noise", _noise_texture_b)
	material.set_shader_parameter("color_gradient", _vertical_gradient)
	_beam_rect.material = material
	var core_material := _shader_material(
		_lenrow_shader(),
		{
			"use_color_gradient": true,
			"color_effect_mod": 0.30,
			"intensive": 0.40,
			"lightning_thin": 4.4,
			"number_lightning": 4,
			"speed": 1.6,
			"position": 0.5,
		}
	)
	core_material.set_shader_parameter("lightning_noise", _noise_texture_b)
	core_material.set_shader_parameter("background_noise", _noise_texture_a)
	core_material.set_shader_parameter("color_gradient", _vertical_gradient)
	_beam_core_rect.position = Vector2(0.0, beam_width * 0.48)
	_beam_core_rect.size = Vector2(beam_length, beam_width * 1.36)
	_beam_core_rect.material = core_material
	_beam_particles.visible = false
	_muzzle_particles.visible = false
	_impact_particles.visible = false


func _apply_lumenfruit_setup() -> void:
	_show_only_rects()
	_beam_rect.visible = true
	_beam_core_rect.visible = true
	_beam_rect.position = Vector2(0.0, -beam_width * 1.08)
	_beam_rect.size = Vector2(beam_length, beam_width * 2.16)
	var material := _shader_material(
		_lumenfruit_shader(),
		{
			"speed": 0.0,
			"variation": 0.28,
			"width": 0.46,
		}
	)
	material.set_shader_parameter("noiseTexture", _noise_texture_a)
	material.set_shader_parameter("color_gradient", _arc_gradient())
	_beam_rect.material = material
	var core_material := _shader_material(
		_lumenfruit_shader(),
		{
			"speed": 0.65,
			"variation": 0.14,
			"width": 0.24,
		}
	)
	core_material.set_shader_parameter("noiseTexture", _noise_texture_b)
	core_material.set_shader_parameter("color_gradient", _arc_core_gradient())
	_beam_core_rect.position = Vector2(0.0, beam_width * 0.40)
	_beam_core_rect.size = Vector2(beam_length, beam_width * 1.36)
	_beam_core_rect.material = core_material
	_beam_particles.visible = false
	_muzzle_particles.visible = false
	_impact_particles.visible = false


func _update_gdquest(progress: float) -> void:
	var fade := _fade_profile(progress)
	var cast_progress := smoothstep(0.0, 0.18, progress)
	var laser_start := 40.0
	var current_length := lerpf(laser_start, beam_length, cast_progress)
	_set_straight_points(current_length)
	_apply_line(
		_back_line,
		beam_width * 2.2 * fade,
		Color(0.06, 0.62, 0.66, 0.25),
		_gradient(Color(0.12, 0.90, 0.94, 0.0), Color(0.12, 0.90, 0.94, 0.38), Color(0.12, 0.90, 0.94, 0.0))
	)
	_apply_line(
		_mid_line,
		beam_width * 1.2 * fade,
		Color(0.30, 1.0, 1.0, 0.82),
		_gradient(Color(0.30, 1.0, 1.0, 0.0), Color(0.30, 1.0, 1.0, 0.88), Color(0.30, 1.0, 1.0, 0.0))
	)
	_apply_line(
		_core_line,
		beam_width * 0.42 * fade,
		Color(0.96, 1.0, 1.0, 1.0),
		null
	)
	_back_line.material = _additive_material()
	_mid_line.material = _additive_material()
	_core_line.material = _additive_material()
	_sync_particles_to_length(current_length)


func _update_goldtime(progress: float) -> void:
	var fade := _fade_profile(progress)
	var pulse := 0.92 + sin(_phase * 18.0) * 0.03
	_beam_rect.modulate = Color(1.0, 1.0, 1.0, fade)
	_beam_rect.size = Vector2(beam_length, beam_width * 0.84 * pulse)


func _update_blaster_glow(progress: float) -> void:
	var fade := _fade_profile(progress)
	var pulse := 0.94 + sin(_phase * 10.0) * 0.05
	_mid_line.modulate = Color(1.0, 1.0, 1.0, fade)
	_mid_line.width = 20.0 * pulse


func _update_lenrow_lightning(progress: float) -> void:
	var fade := _fade_profile(progress)
	_beam_rect.modulate = Color(1.0, 1.0, 1.0, fade)
	_beam_core_rect.modulate = Color(1.0, 1.0, 1.0, fade)


func _update_lumenfruit_arc(progress: float) -> void:
	var fade := _fade_profile(progress)
	_beam_rect.modulate = Color(1.0, 1.0, 1.0, fade)
	_beam_core_rect.modulate = Color(1.0, 1.0, 1.0, fade)


func _show_only_lines() -> void:
	for line in [_back_line, _mid_line, _core_line, _detail_line]:
		line.visible = false
	_beam_rect.visible = false
	_beam_core_rect.visible = false


func _show_only_rects() -> void:
	for line in [_back_line, _mid_line, _core_line, _detail_line]:
		line.visible = false
	_beam_rect.visible = false
	_beam_core_rect.visible = false


func _apply_line(line: Line2D, width: float, color: Color, gradient: Gradient) -> void:
	line.width = width
	line.default_color = color
	line.gradient = gradient


func _set_straight_points(length: float) -> void:
	var points := PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])
	for line in [_back_line, _mid_line, _core_line, _detail_line]:
		line.points = points
	_impact_particles.position = Vector2(length, 0.0)
	_beam_particles.position = Vector2(length * 0.5, 0.0)


func _sync_particles_to_length(length: float) -> void:
	_beam_particles.position = Vector2(length * 0.5, 0.0)
	_impact_particles.position = Vector2(length, 0.0)
	var beam_material := _beam_particles.process_material as ParticleProcessMaterial
	if beam_material:
		beam_material.emission_box_extents.x = length * 0.5


func _apply_particle_set(
	beam_color: Color,
	muzzle_color: Color,
	impact_color: Color,
	beam_amount: int,
	muzzle_amount: int,
	impact_amount: int
) -> void:
	_beam_particles.amount = beam_amount
	_beam_particles.lifetime = 0.25
	_beam_particles.preprocess = 0.2
	_beam_particles.randomness = 0.7
	_beam_particles.process_material = _beam_particle_material(beam_length, beam_color)
	_beam_particles.emitting = _beam_particles.visible

	_muzzle_particles.amount = muzzle_amount
	_muzzle_particles.lifetime = 0.22
	_muzzle_particles.preprocess = 0.04
	_muzzle_particles.randomness = 0.72
	_muzzle_particles.process_material = _burst_particle_material(muzzle_color, true)
	_muzzle_particles.emitting = _muzzle_particles.visible

	_impact_particles.amount = impact_amount
	_impact_particles.lifetime = 0.22
	_impact_particles.preprocess = 0.04
	_impact_particles.randomness = 0.68
	_impact_particles.process_material = _burst_particle_material(impact_color, false)
	_impact_particles.emitting = _impact_particles.visible


func _beam_particle_material(length: float, color: Color) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(length * 0.5, beam_width * 0.45, 1.0)
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 8.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 18.0
	material.initial_velocity_max = 76.0
	material.scale_min = 0.12
	material.scale_max = 0.58
	material.color = color
	material.color_ramp = _particle_ramp(color)
	material.particle_flag_disable_z = true
	return material


func _burst_particle_material(color: Color, forward: bool) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = beam_width * 0.75
	material.direction = Vector3(1.0 if forward else -1.0, 0.0, 0.0)
	material.spread = 72.0 if forward else 140.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 70.0
	material.initial_velocity_max = 220.0
	material.scale_min = 0.18
	material.scale_max = 1.0
	material.color = color
	material.color_ramp = _particle_ramp(color)
	material.particle_flag_disable_z = true
	return material


func _restart_particles() -> void:
	for particles in [_beam_particles, _muzzle_particles, _impact_particles]:
		particles.restart()
		particles.emitting = particles.visible


func _gradient(start: Color, middle: Color, ending: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.add_point(0.0, start)
	gradient.add_point(0.5, middle)
	gradient.add_point(1.0, ending)
	return gradient


func _particle_ramp(color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.18, Color(color.r, color.g, color.b, color.a))
	gradient.add_point(0.75, Color(color.r, color.g, color.b, color.a * 0.35))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 64
	return texture


func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func _shader_material(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in params.keys():
		material.set_shader_parameter(StringName(key), params[key])
	return material


func _make_line_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.16, Color(1.0, 1.0, 1.0, 0.68))
	gradient.add_point(0.50, Color(1.0, 1.0, 1.0, 1.0))
	gradient.add_point(0.84, Color(1.0, 1.0, 1.0, 0.68))
	gradient.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.width = 96
	texture.height = 24
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.gradient = gradient
	return texture


func _make_soft_particle_texture() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var uv := Vector2(float(x) / 63.0, float(y) / 63.0)
			var dist := uv.distance_to(Vector2(0.5, 0.5)) * 2.0
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_noise_texture(seed: int) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.035
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.55
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 32
	texture.noise = noise
	texture.seamless = true
	return texture


func _make_vertical_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.02, 0.14, 0.50, 0.0))
	gradient.add_point(0.18, Color(0.16, 0.44, 1.0, 0.55))
	gradient.add_point(0.50, Color(0.95, 1.0, 1.0, 1.0))
	gradient.add_point(0.82, Color(0.16, 0.44, 1.0, 0.55))
	gradient.add_point(1.0, Color(0.02, 0.14, 0.50, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 128
	return texture


func _arc_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.10, 0.00, 0.16, 0.0))
	gradient.add_point(0.15, Color(0.42, 0.00, 0.72, 0.45))
	gradient.add_point(0.50, Color(1.0, 0.82, 1.0, 1.0))
	gradient.add_point(0.85, Color(0.42, 0.00, 0.72, 0.45))
	gradient.add_point(1.0, Color(0.10, 0.00, 0.16, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 128
	return texture


func _arc_core_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.12, 0.00, 0.20, 0.0))
	gradient.add_point(0.22, Color(0.88, 0.10, 1.0, 0.55))
	gradient.add_point(0.50, Color(1.0, 0.96, 1.0, 1.0))
	gradient.add_point(0.78, Color(0.88, 0.10, 1.0, 0.55))
	gradient.add_point(1.0, Color(0.12, 0.00, 0.20, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 128
	return texture


func _fade_profile(progress: float) -> float:
	var fade_in := smoothstep(0.0, 0.10, progress)
	var fade_out := 1.0 - smoothstep(0.82, 1.0, progress)
	return clampf(fade_in * fade_out, 0.0, 1.0)


func _goldtime_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 laser_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float flicker_speed = 5.0;
uniform float flicker_strength = 2.0;
uniform float wave_strength = 0.1;
uniform float core_power = 1.0;

void fragment() {
	float time = TIME * flicker_speed * -1.0;
	float wave = sin(UV.x * 40.0 + time) * wave_strength;
	float flicker = 1.0 + sin(time * 2.0 + UV.x * 10.0) * flicker_strength;
	float center_dist = abs(UV.y - 0.5) * 2.0;
	float core = pow(1.0 - center_dist, core_power);
	float intensity = max(core * flicker + wave, 0.0);
	COLOR = laser_color * intensity;
}
"""
	return shader


func _blaster_glow_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 50.0) = 6.0;
uniform float core_width : hint_range(0.0, 1.0) = 0.5;
uniform float core_length : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float y_dist = abs(UV.y - 0.5);
	float x_dist = max(0.1, abs(UV.x - 0.5));
	float core_y_mask = 1.0 - smoothstep(0.0, core_width, y_dist);
	float core_x_mask = 1.0 - smoothstep(0.0, core_length, x_dist);
	float core_mask = core_y_mask * core_x_mask;
	vec4 core_color = COLOR * glow_intensity;
	core_color.a = core_mask;
	COLOR = core_color;
}
"""
	return shader


func _lenrow_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D lightning_noise : repeat_enable;
uniform sampler2D background_noise : repeat_enable;
uniform sampler2D color_gradient;
uniform bool use_color_gradient = false;
uniform float color_effect_mod : hint_range(0.0, 3.0, 0.05) = 0.5;
uniform float intensive : hint_range(0.0, 5.0, 0.05) = 0.8;
uniform float lightning_thin = 2.0;
uniform int number_lightning = 8;
uniform float speed = 1.0;
uniform float position : hint_range(0.0, 1.0, 0.05) = 0.5;

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 old_color = COLOR;
	if (use_color_gradient) {
		old_color = texture(color_gradient, vec2(UV.y, 0.0));
	}
	COLOR = vec4(0.0);
	float time = TIME * speed;
	for (int i = 0; i < number_lightning; i++) {
		float offset_x = random(vec2(time + float(i)));
		vec2 noise_coords = vec2(UV.x + time * 0.4 * (0.5 + fract(sin(float(i) * 50.0))), abs(UV.y - 0.5));
		vec2 offset = (texture(lightning_noise, noise_coords).rg - vec2(0.5)) * intensive;
		vec2 uv_off = UV + offset;
		float dist_x = abs(uv_off.y - position) * lightning_thin;
		float color_lower_bound = 0.1 + 0.5 * (float(i) - 0.5);
		float color_mod = smoothstep(color_lower_bound, 1.0, texture(background_noise, vec2(UV.x + offset_x, UV.y)).x);
		vec4 new_color = old_color * color_mod / max(dist_x, 0.001);
		new_color *= 0.1 * texture(background_noise, uv_off + vec2(time, 0.0)).r;
		COLOR += new_color;
		COLOR.a -= min(color_effect_mod, new_color.a);
	}
}
"""
	return shader


func _lumenfruit_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D color_gradient;
uniform sampler2D noiseTexture;
uniform float speed : hint_range(0.0, 5.0) = 0.75;
uniform float variation : hint_range(0.0, 1.0) = 0.45;
uniform float width : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	vec2 noise_uv = vec2(UV.x + TIME * speed, UV.y - TIME * speed);
	float noise_sample = texture(noiseTexture, noise_uv).r;
	float x_offset = noise_sample * variation - variation / 2.0;
	float sample_x = (UV.y - 0.5) / width + 0.5 + x_offset / width;
	float alpha_mask = step(0.0, sample_x) * step(sample_x, 1.0);
	vec4 col = texture(color_gradient, vec2(clamp(sample_x, 0.0, 1.0), UV.x));
	COLOR = vec4(col.rgb, col.a * alpha_mask);
}
"""
	return shader
