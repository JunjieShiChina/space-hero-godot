extends Node2D
class_name BossLaserWarning

@export var warning_delay := 1.0
@export var default_active_life := 2.0
@export var bullet_type := "BulletLaser"
@export var warning_width_design := 4.0
@export var laser_width_design := 20.0
@export var laser_start_distance_design := 28.0
@export var combat_bottom_margin_design := 150.0

var shooter_team := "enemy"
var direction := Vector2.DOWN
var bullet_overrides: Dictionary = {}

var _timer := 0.0
var _laser_activated := false
var _active_laser: SpaceBullet = null
var _beam_length := 0.0
var _flicker_phase := 0.0
var _particle_texture: Texture2D
var _active_laser_life := 2.0
var _laser_start_distance := 0.0
var _follow_owner: Node2D = null
var _follow_offset := Vector2.ZERO

@onready var _warning_glow_line: Line2D = $WarningGlowLine
@onready var _warning_core_line: Line2D = $WarningCoreLine
@onready var _muzzle_particles: GPUParticles2D = $MuzzleParticles

const SCREEN_MARGIN := 180.0


func _ready() -> void:
	_configure_warning_effect()


func fire(origin: Vector2, aim_direction: Vector2, team := "enemy", overrides := {}) -> void:
	_follow_owner = overrides.get("follow_owner") as Node2D
	_follow_offset = overrides.get("follow_offset", Vector2.ZERO)
	global_position = origin
	direction = _safe_direction(aim_direction)
	rotation = direction.angle()
	shooter_team = team
	bullet_overrides = overrides.duplicate()
	_timer = 0.0
	_laser_activated = false
	_active_laser = null
	_active_laser_life = maxf(0.05, float(bullet_overrides.get("life", default_active_life)))
	_beam_length = _screen_exit_distance(direction)
	_laser_start_distance = minf(
		DisplaySettings.scale_value(float(bullet_overrides.get(
			"start_distance",
			laser_start_distance_design
		))),
		_beam_length - 1.0
	)
	_set_warning_visible(true)
	_configure_warning_effect()
	set_process(true)


func has_active_laser() -> bool:
	return is_instance_valid(_active_laser) and not _active_laser.retired


func active_laser() -> SpaceBullet:
	return _active_laser if has_active_laser() else null


func _process(delta: float) -> void:
	_sync_follow_transform()
	_timer += delta
	_flicker_phase += delta * 24.0
	_update_warning_alpha()
	if not _laser_activated and _timer >= warning_delay:
		_activate_laser()
	if _timer >= warning_delay + _active_laser_life:
		_retire()


func _activate_laser() -> void:
	if _laser_activated:
		return
	_sync_follow_transform()
	_laser_activated = true
	_set_warning_visible(false)
	AudioBus.play_sfx(SpaceBullet.bullet_info(bullet_type).sfx, -14.0)

	var overrides := bullet_overrides.duplicate()
	overrides["life"] = _active_laser_life
	overrides["length"] = _beam_length / DisplaySettings.scale_factor()
	overrides["width"] = laser_width_design
	overrides["start_distance"] = _laser_start_distance / DisplaySettings.scale_factor()
	if _follow_owner != null:
		overrides["follow_owner"] = _follow_owner
		overrides["follow_offset"] = _follow_offset
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
	_configure_line(_warning_glow_line, width * 2.8, Color(1.0, 0.10, 0.05, 0.42))
	_configure_line(_warning_core_line, width * 1.15, Color(1.0, 0.22, 0.18, 1.0))
	_configure_muzzle_particles(width)


func _configure_line(line: Line2D, width: float, color: Color) -> void:
	if line == null:
		return
	line.points = PackedVector2Array([
		Vector2(_laser_start_distance, 0.0),
		Vector2(_beam_length, 0.0)
	])
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.round_precision = 10
	line.material = null
	line.gradient = null
	line.z_index = 1 if line == _warning_glow_line else 2


func _configure_muzzle_particles(width: float) -> void:
	if _muzzle_particles == null:
		return
	_muzzle_particles.position = Vector2(_laser_start_distance, 0.0)
	_muzzle_particles.amount = 18
	_muzzle_particles.lifetime = 0.18
	_muzzle_particles.preprocess = 0.08
	_muzzle_particles.randomness = 0.60
	_muzzle_particles.fixed_fps = 30
	_muzzle_particles.local_coords = true
	_muzzle_particles.visibility_rect = Rect2(
		Vector2(-width * 12.0, -width * 12.0),
		Vector2.ONE * width * 24.0
	)
	_muzzle_particles.texture = _soft_particle_texture()
	_muzzle_particles.material = _additive_material()
	_muzzle_particles.process_material = _make_muzzle_particle_material(width * 1.4)
	_muzzle_particles.emitting = true
	_muzzle_particles.restart()


func _update_warning_alpha() -> void:
	var pulse := 0.70 + sin(_flicker_phase) * 0.18 + sin(_flicker_phase * 0.41) * 0.08
	if _warning_glow_line:
		_warning_glow_line.modulate.a = clampf(pulse * 0.72, 0.28, 0.72)
	if _warning_core_line:
		_warning_core_line.modulate.a = clampf(pulse * 1.05, 0.72, 1.0)


func _set_warning_visible(is_visible: bool) -> void:
	for node in [_warning_glow_line, _warning_core_line, _muzzle_particles]:
		if node == null:
			continue
		node.visible = is_visible
		if node is GPUParticles2D:
			(node as GPUParticles2D).emitting = is_visible


func _screen_exit_distance(value: Vector2) -> float:
	var viewport_size := DisplaySettings.logical_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var safe_bottom := viewport_size.y - DisplaySettings.scale_value(combat_bottom_margin_design)
	var candidates: Array[float] = []
	if absf(value.x) > 0.0001:
		candidates.append((0.0 - global_position.x) / value.x)
		candidates.append((viewport_size.x - global_position.x) / value.x)
	if absf(value.y) > 0.0001:
		candidates.append((0.0 - global_position.y) / value.y)
		candidates.append((safe_bottom - global_position.y) / value.y)
	var best := INF
	for candidate in candidates:
		if candidate > DisplaySettings.scale_value(32.0):
			best = minf(best, candidate)
	if is_inf(best):
		best = viewport_size.length()
	return best + DisplaySettings.scale_value(SCREEN_MARGIN)


func _make_muzzle_particle_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * 0.95
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 22.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(48.0)
	material.initial_velocity_max = DisplaySettings.scale_value(126.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.45
	material.scale_max = DisplaySettings.scale_factor() * 1.35
	material.angular_velocity_min = -80.0
	material.angular_velocity_max = 80.0
	material.color = Color(1.0, 0.16, 0.08, 0.74)
	material.color_ramp = _particle_ramp(Color(1.0, 0.16, 0.08, 0.78))
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


func _sync_follow_transform() -> void:
	if _follow_owner == null:
		return
	if not is_instance_valid(_follow_owner) or _follow_owner.is_queued_for_deletion():
		_retire()
		return
	global_position = _follow_owner.to_global(_follow_offset)


func _spawn_parent() -> Node:
	var parent := get_parent()
	if parent:
		return parent
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
