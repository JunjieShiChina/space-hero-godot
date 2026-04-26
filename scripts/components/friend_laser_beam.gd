extends Area2D
class_name FriendLaserBeam

@export var length_design := 560.0
@export var width_design := 13.0
@export var damage := 1.0
@export var tick_interval := 0.08
@export var life_time := 0.38
@export var extend_to_edge := true

var shooter_team := "player"
var anchor: Node2D
var anchor_offset := Vector2.ZERO
var local_direction := Vector2.UP
var _tick_timer := 0.0
var _retired := false
var _current_length := 0.0
var _current_width := 0.0
var _flicker_phase := 0.0
var _hit_body: CombatBody
var _hit_position := Vector2.ZERO

@onready var _core_line: Line2D = get_node_or_null("CoreLine") as Line2D
@onready var _glow_line: Line2D = get_node_or_null("GlowLine") as Line2D
@onready var _beam_particles: GPUParticles2D = get_node_or_null("BeamParticles") as GPUParticles2D
@onready var _muzzle_particles: GPUParticles2D = get_node_or_null("MuzzleParticles") as GPUParticles2D
@onready var _impact_particles: GPUParticles2D = get_node_or_null("ImpactParticles") as GPUParticles2D
@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	_apply_dimensions()


func fire(origin: Vector2, direction: Vector2, team_name: String, overrides := {}) -> void:
	global_position = origin
	var safe_direction := Vector2.UP if direction.is_zero_approx() else direction.normalized()
	rotation = safe_direction.angle()
	anchor = null
	anchor_offset = Vector2.ZERO
	local_direction = safe_direction
	shooter_team = team_name
	_apply_overrides(overrides)
	_arm()


func fire_from_anchor(source: Node2D, offset: Vector2, direction: Vector2, team_name: String, overrides := {}) -> void:
	anchor = source
	anchor_offset = offset
	local_direction = Vector2.UP if direction.is_zero_approx() else direction.normalized()
	shooter_team = team_name
	_apply_overrides(overrides)
	_update_anchor_transform()
	_arm()


func _apply_overrides(overrides: Dictionary) -> void:
	if overrides.has("length"):
		length_design = float(overrides["length"])
	if overrides.has("width"):
		width_design = float(overrides["width"])
	if overrides.has("damage"):
		damage = float(overrides["damage"])
	if overrides.has("life"):
		life_time = float(overrides["life"])
	if overrides.has("extend_to_edge"):
		extend_to_edge = bool(overrides["extend_to_edge"])


func _arm() -> void:
	collision_layer = 4 if shooter_team == "player" else 8
	collision_mask = 2 | 32 if shooter_team == "player" else 1 | 32
	monitoring = true
	monitorable = false
	_apply_dimensions()
	_restart_particles()


func _physics_process(delta: float) -> void:
	if _retired:
		return
	_flicker_phase += delta * 42.0
	if anchor:
		if not is_instance_valid(anchor):
			_retire()
			return
		_update_anchor_transform()
	_apply_dimensions()
	life_time -= delta
	if life_time <= 0.0:
		_retire()
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_damage_overlapping_targets()


func _damage_overlapping_targets() -> void:
	if _hit_body != null and is_instance_valid(_hit_body) and not _hit_body.dead:
		_hit_body.take_damage(damage)


func _apply_dimensions() -> void:
	var length := _laser_length()
	var width := DisplaySettings.scale_value(width_design)
	var pulse := 0.88 + sin(_flicker_phase) * 0.08 + sin(_flicker_phase * 0.37) * 0.04
	_current_length = length
	_current_width = width
	_configure_line(_glow_line, length, width * 2.35 * pulse, Color(1.0, 0.74, 0.22, 0.30))
	_configure_line(_core_line, length, width * 0.76 * pulse, Color(1.0, 0.98, 0.68, 1.0))
	_configure_collision(length, width * 1.15)
	_configure_particles(length, width * pulse)


func _configure_line(line: Line2D, length: float, width: float, color: Color) -> void:
	if line == null:
		return
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.gradient = null if line == _core_line else _line_gradient(color)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	if line.material == null:
		var canvas_material := CanvasItemMaterial.new()
		canvas_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		line.material = canvas_material


func _configure_collision(length: float, width: float) -> void:
	if _collision_shape == null:
		return
	if _collision_shape.shape == null or not _collision_shape.shape is RectangleShape2D:
		_collision_shape.shape = RectangleShape2D.new()
	var rectangle := _collision_shape.shape as RectangleShape2D
	rectangle.size = Vector2(length, width)
	_collision_shape.position = Vector2(length * 0.5, 0.0)
	_collision_shape.disabled = false


func _configure_particles(length: float, width: float) -> void:
	if _beam_particles:
		_beam_particles.position = Vector2(length * 0.5, 0.0)
		_beam_particles.amount = 96
		_beam_particles.lifetime = 0.18
		_beam_particles.preprocess = 0.18
		_beam_particles.randomness = 0.52
		_beam_particles.fixed_fps = 30
		_beam_particles.visibility_rect = Rect2(Vector2(-length * 0.55, -width * 8.0), Vector2(length * 1.1, width * 16.0))
		_beam_particles.material = _additive_material()
		_beam_particles.process_material = _make_beam_material(length, width)
	if _muzzle_particles:
		_muzzle_particles.position = Vector2.ZERO
		_muzzle_particles.amount = 34
		_muzzle_particles.lifetime = 0.20
		_muzzle_particles.preprocess = 0.05
		_muzzle_particles.randomness = 0.62
		_muzzle_particles.fixed_fps = 30
		_muzzle_particles.visibility_rect = Rect2(Vector2(-width * 4.0, -width * 4.0), Vector2(width * 12.0, width * 8.0))
		_muzzle_particles.material = _additive_material()
		_muzzle_particles.process_material = _make_muzzle_material(width)
	if _impact_particles:
		_impact_particles.position = Vector2(length, 0.0)
		_impact_particles.amount = 42
		_impact_particles.lifetime = 0.16
		_impact_particles.preprocess = 0.04
		_impact_particles.randomness = 0.54
		_impact_particles.fixed_fps = 30
		_impact_particles.visibility_rect = Rect2(Vector2(-width * 8.0, -width * 8.0), Vector2.ONE * width * 16.0)
		_impact_particles.material = _additive_material()
		_impact_particles.process_material = _make_impact_material(width)
		_impact_particles.emitting = _hit_body != null and is_instance_valid(_hit_body)


func _make_beam_material(length: float, width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(length * 0.5, width * 0.72, 1.0)
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 5.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(42.0)
	material.initial_velocity_max = DisplaySettings.scale_value(120.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.45
	material.scale_max = DisplaySettings.scale_factor() * 1.45
	material.color = Color(1.0, 0.88, 0.34, 0.48)
	material.color_ramp = _make_laser_ramp()
	material.particle_flag_disable_z = true
	return material


func _make_muzzle_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * 1.8
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 28.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(120.0)
	material.initial_velocity_max = DisplaySettings.scale_value(300.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.8
	material.scale_max = DisplaySettings.scale_factor() * 2.6
	material.color = Color(1.0, 0.90, 0.46, 0.86)
	material.color_ramp = _make_laser_ramp()
	material.particle_flag_disable_z = true
	return material


func _make_impact_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * 1.6
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 120.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(90.0)
	material.initial_velocity_max = DisplaySettings.scale_value(260.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.8
	material.scale_max = DisplaySettings.scale_factor() * 2.4
	material.color = Color(1.0, 0.78, 0.22, 0.9)
	material.color_ramp = _make_laser_ramp()
	material.particle_flag_disable_z = true
	return material


func _make_laser_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.82, 0.22, 0.0))
	gradient.set_color(1, Color(1.0, 0.42, 0.05, 0.0))
	gradient.add_point(0.12, Color(1.0, 1.0, 0.72, 0.95))
	gradient.add_point(0.48, Color(1.0, 0.82, 0.24, 0.76))
	gradient.add_point(0.80, Color(1.0, 0.46, 0.12, 0.16))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _line_gradient(color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.04, Color(color.r, color.g, color.b, color.a * 0.72))
	gradient.add_point(0.18, color)
	gradient.add_point(0.84, color)
	gradient.add_point(0.98, Color(color.r, color.g, color.b, color.a * 0.22))
	return gradient


func _update_anchor_transform() -> void:
	var offset := anchor_offset.rotated(anchor.global_rotation)
	global_position = anchor.global_position + offset
	var direction := local_direction.rotated(anchor.global_rotation)
	rotation = direction.angle()


func _laser_length() -> float:
	var fallback := DisplaySettings.scale_value(length_design)
	_hit_body = null
	_hit_position = Vector2.ZERO
	if not extend_to_edge:
		return fallback
	var direction := Vector2.RIGHT.rotated(rotation).normalized()
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DisplaySettings.logical_size()
	var candidates: Array[float] = []
	if absf(direction.x) > 0.0001:
		candidates.append((0.0 - global_position.x) / direction.x)
		candidates.append((viewport_size.x - global_position.x) / direction.x)
	if absf(direction.y) > 0.0001:
		candidates.append((0.0 - global_position.y) / direction.y)
		candidates.append((viewport_size.y - global_position.y) / direction.y)
	var best := INF
	for value in candidates:
		if value > DisplaySettings.scale_value(48.0):
			best = minf(best, value)
	if is_inf(best) or best <= DisplaySettings.scale_value(48.0):
		best = fallback
	var ray_hit := _raycast_hit(direction, best)
	if not ray_hit.is_empty():
		_hit_body = ray_hit["collider"] as CombatBody
		_hit_position = ray_hit["position"] as Vector2
		best = minf(best, global_position.distance_to(_hit_position))
	return best


func _raycast_hit(direction: Vector2, length: float) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + direction * length)
	query.collision_mask = 2 if shooter_team == "player" else 1
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return {}
	var collider := result.get("collider") as Object
	if collider is CombatBody:
		var body := collider as CombatBody
		if body.team != shooter_team and not body.dead:
			return result
	return {}


func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func _restart_particles() -> void:
	for particles in [_beam_particles, _muzzle_particles]:
		if particles == null:
			continue
		particles.emitting = true
		particles.restart()


func _retire() -> void:
	if _retired:
		return
	_retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	queue_free()
