extends Node2D
class_name BossLaserWarning

@export var warning_delay := 1.0
@export var total_life := 3.0
@export var bullet_type := "BulletLaser"
@export var warning_width_design := 5.0
@export var laser_width_design := 20.0

var shooter_team := "enemy"
var direction := Vector2.DOWN
var bullet_overrides: Dictionary = {}

var _timer := 0.0
var _laser_activated := false
var _active_laser: SpaceBullet = null
var _beam_length := 0.0
var _flicker_phase := 0.0
var _line_shader: Shader
var _particle_texture: Texture2D

@onready var _warning_beam_sprite: Sprite2D = get_node_or_null("WarningBeamSprite") as Sprite2D
@onready var _warning_glow_line: Line2D = $WarningGlowLine
@onready var _warning_core_line: Line2D = $WarningCoreLine
@onready var _warning_particles: GPUParticles2D = $WarningParticles
@onready var _muzzle_particles: GPUParticles2D = $MuzzleParticles

const SCREEN_MARGIN := 180.0

func _ready() -> void:
	_configure_warning_effect()

func fire(origin: Vector2, aim_direction: Vector2, team := "enemy", overrides := {}) -> void:
	global_position = origin
	direction = _safe_direction(aim_direction)
	rotation = direction.angle()
	shooter_team = team
	bullet_overrides = overrides.duplicate()
	_timer = 0.0
	_laser_activated = false
	_active_laser = null
	_beam_length = _screen_exit_distance(direction)
	_set_warning_visible(true)
	_configure_warning_effect()
	set_process(true)

func has_active_laser() -> bool:
	return is_instance_valid(_active_laser) and not _active_laser.retired

func active_laser() -> SpaceBullet:
	return _active_laser if has_active_laser() else null

func _process(delta: float) -> void:
	_timer += delta
	_flicker_phase += delta * 24.0
	_update_warning_alpha()
	if not _laser_activated and _timer >= warning_delay:
		_activate_laser()
	if _timer >= total_life:
		_retire()

func _activate_laser() -> void:
	if _laser_activated:
		return
	_laser_activated = true
	_set_warning_visible(false)
	AudioBus.play_sfx(SpaceBullet.bullet_info(bullet_type).sfx, -14.0)

	var overrides := bullet_overrides.duplicate()
	overrides["life"] = maxf(0.05, total_life - _timer)
	overrides["length"] = _beam_length / DisplaySettings.scale_factor()
	overrides["width"] = laser_width_design
	overrides["enemy_laser_color"] = true
	var laser := SpaceBullet.create(bullet_type)
	_spawn_parent().add_child(laser)
	laser.setup(bullet_type, shooter_team, global_position, direction, overrides)
	_active_laser = laser

func _retire() -> void:
	if is_queued_for_deletion():
		return
	if has_active_laser():
		_active_laser.call_deferred("_retire")
	queue_free()

func _configure_warning_effect() -> void:
	var width := DisplaySettings.scale_value(warning_width_design)
	_configure_warning_sprite(width)
	_configure_line(
		_warning_glow_line,
		width * 5.2,
		Color(1.0, 0.06, 0.01, 0.18),
		"warning_glow"
	)
	_configure_line(
		_warning_core_line,
		width * 1.25,
		Color(1.0, 0.04, 0.01, 0.86),
		"warning_core"
	)
	_configure_particles(width)

func _configure_warning_sprite(width: float) -> void:
	if _warning_beam_sprite == null or _warning_beam_sprite.texture == null:
		return
	_warning_beam_sprite.position = Vector2(_beam_length * 0.5, 0.0)
	_warning_beam_sprite.rotation = -PI / 2.0
	var texture_size := _warning_beam_sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var beam_width := width * 3.4
	_warning_beam_sprite.scale = Vector2(
		beam_width / texture_size.x,
		_beam_length / texture_size.y
	)
	_warning_beam_sprite.material = _additive_material()
	_warning_beam_sprite.modulate = Color(1.0, 0.10, 0.03, 0.38)
	_warning_beam_sprite.z_index = 0

func _configure_line(line: Line2D, width: float, color: Color, profile: String) -> void:
	if line == null:
		return
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(_beam_length, 0.0)])
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.round_precision = 10
	line.material = _line_material()
	line.gradient = _line_gradient(color, profile)
	line.z_index = 1 if profile == "warning_glow" else 2

func _configure_particles(width: float) -> void:
	if _warning_particles:
		_warning_particles.position = Vector2(_beam_length * 0.5, 0.0)
		_warning_particles.amount = 150
		_warning_particles.lifetime = 0.30
		_warning_particles.preprocess = 0.30
		_warning_particles.randomness = 0.70
		_warning_particles.fixed_fps = 30
		_warning_particles.local_coords = true
		_warning_particles.visibility_rect = Rect2(
			Vector2(-_beam_length * 0.55, -width * 12.0),
			Vector2(_beam_length * 1.1, width * 24.0)
		)
		_warning_particles.texture = _soft_particle_texture()
		_warning_particles.material = _additive_material()
		_warning_particles.process_material = _make_warning_particle_material(width)
		_warning_particles.emitting = true
		_warning_particles.restart()
	if _muzzle_particles:
		_muzzle_particles.position = Vector2.ZERO
		_muzzle_particles.amount = 72
		_muzzle_particles.lifetime = 0.24
		_muzzle_particles.preprocess = 0.08
		_muzzle_particles.randomness = 0.74
		_muzzle_particles.fixed_fps = 30
		_muzzle_particles.local_coords = true
		_muzzle_particles.visibility_rect = Rect2(
			Vector2(-width * 8.0, -width * 8.0),
			Vector2.ONE * width * 16.0
		)
		_muzzle_particles.texture = _soft_particle_texture()
		_muzzle_particles.material = _additive_material()
		_muzzle_particles.process_material = _make_muzzle_particle_material(width)
		_muzzle_particles.emitting = true
		_muzzle_particles.restart()

func _update_warning_alpha() -> void:
	var pulse := 0.70 + sin(_flicker_phase) * 0.18 + sin(_flicker_phase * 0.41) * 0.08
	if _warning_beam_sprite:
		_warning_beam_sprite.modulate.a = clampf(pulse * 0.54, 0.26, 0.58)
	if _warning_glow_line:
		_warning_glow_line.modulate.a = clampf(pulse * 0.62, 0.24, 0.76)
	if _warning_core_line:
		_warning_core_line.modulate.a = clampf(pulse, 0.48, 1.0)

func _set_warning_visible(is_visible: bool) -> void:
	for node in [
		_warning_beam_sprite,
		_warning_glow_line,
		_warning_core_line,
		_warning_particles,
		_muzzle_particles
	]:
		if node == null:
			continue
		node.visible = is_visible
		if node is GPUParticles2D:
			(node as GPUParticles2D).emitting = is_visible

func _screen_exit_distance(value: Vector2) -> float:
	var viewport_size := DisplaySettings.logical_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var candidates: Array[float] = []
	if absf(value.x) > 0.0001:
		candidates.append((0.0 - global_position.x) / value.x)
		candidates.append((viewport_size.x - global_position.x) / value.x)
	if absf(value.y) > 0.0001:
		candidates.append((0.0 - global_position.y) / value.y)
		candidates.append((viewport_size.y - global_position.y) / value.y)
	var best := INF
	for candidate in candidates:
		if candidate > DisplaySettings.scale_value(32.0):
			best = minf(best, candidate)
	if is_inf(best):
		best = viewport_size.length()
	return best + DisplaySettings.scale_value(SCREEN_MARGIN)

func _line_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _warning_shader()
	material.set_shader_parameter("pulse_speed", 9.0)
	material.set_shader_parameter("wave_density", 18.0)
	return material

func _warning_shader() -> Shader:
	if _line_shader:
		return _line_shader
	_line_shader = Shader.new()
	_line_shader.code = """
shader_type canvas_item;

uniform float pulse_speed = 9.0;
uniform float wave_density = 18.0;

void fragment() {
	vec4 base = COLOR;
	float wave_a = 0.5 + 0.5 * sin(UV.x * wave_density - TIME * pulse_speed);
	float wave_b = 0.5 + 0.5 * sin(UV.x * (wave_density * 0.37) + TIME * pulse_speed * 0.58);
	float scan = smoothstep(0.22, 1.0, max(wave_a, wave_b * 0.82));
	float edge = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = smoothstep(0.12, 0.72, edge);
	float boost = 0.72 + scan * 0.52 + core * 0.20;
	float alpha = 0.48 + scan * 0.36 + core * 0.16;
	COLOR = vec4(base.rgb * boost, base.a * alpha);
}
"""
	return _line_shader

func _line_gradient(color: Color, profile: String) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var middle_alpha := color.a if profile == "warning_core" else color.a * 0.72
	gradient.add_point(0.025, Color(color.r, color.g, color.b, color.a * 0.85))
	gradient.add_point(0.22, Color(color.r, color.g, color.b, middle_alpha))
	gradient.add_point(0.72, Color(color.r, color.g, color.b, middle_alpha))
	gradient.add_point(0.96, Color(color.r, color.g, color.b, color.a * 0.20))
	return gradient

func _make_warning_particle_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(_beam_length * 0.5, width * 1.15, 1.0)
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 7.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(34.0)
	material.initial_velocity_max = DisplaySettings.scale_value(118.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.60
	material.scale_max = DisplaySettings.scale_factor() * 1.85
	material.angular_velocity_min = -90.0
	material.angular_velocity_max = 90.0
	material.color = Color(1.0, 0.08, 0.02, 0.68)
	material.color_ramp = _particle_ramp(Color(1.0, 0.08, 0.02, 0.82))
	material.particle_flag_disable_z = true
	return material

func _make_muzzle_particle_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * 3.0
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 38.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(120.0)
	material.initial_velocity_max = DisplaySettings.scale_value(310.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.90
	material.scale_max = DisplaySettings.scale_factor() * 2.80
	material.color = Color(1.0, 0.12, 0.03, 0.88)
	material.color_ramp = _particle_ramp(Color(1.0, 0.10, 0.03, 0.9))
	material.particle_flag_disable_z = true
	return material

func _particle_ramp(color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.12, Color(1.0, 0.46, 0.18, color.a))
	gradient.add_point(0.42, Color(color.r, color.g, color.b, color.a * 0.62))
	gradient.add_point(0.78, Color(color.r, color.g, color.b, color.a * 0.18))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _soft_particle_texture() -> Texture2D:
	if _particle_texture:
		return _particle_texture
	var size := 9
	var center := Vector2(size * 0.5 - 0.5, size * 0.5 - 0.5)
	var radius := float(size) * 0.5
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var alpha := clampf(1.0 - distance / radius, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))
	_particle_texture = ImageTexture.create_from_image(image)
	return _particle_texture

func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

func _safe_direction(value: Vector2) -> Vector2:
	if value.is_zero_approx():
		return Vector2.DOWN
	return value.normalized()

func _spawn_parent() -> Node:
	var parent := get_parent()
	if parent:
		return parent
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
