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
@onready var _outer_glow_line: Line2D = get_node_or_null("OuterGlowLine") as Line2D
@onready var _hot_line: Line2D = get_node_or_null("HotLine") as Line2D
@onready var _beam_particles: GPUParticles2D = get_node_or_null("BeamParticles") as GPUParticles2D
@onready var _muzzle_particles: GPUParticles2D = get_node_or_null("MuzzleParticles") as GPUParticles2D
@onready var _side_particles: GPUParticles2D = get_node_or_null("SideParticles") as GPUParticles2D
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
	_flicker_phase += delta * 28.0
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
		var has_hit_position := _hit_position != Vector2.ZERO
		var damage_position := _hit_position if has_hit_position else _hit_body.global_position
		_hit_body.take_damage(SpaceBullet.roll_damage(damage), damage_position, true)


func _apply_dimensions() -> void:
	var length := _laser_length()
	var width := DisplaySettings.scale_value(width_design)
	var pulse := 0.88 + sin(_flicker_phase) * 0.08 + sin(_flicker_phase * 0.37) * 0.04
	_current_length = length
	_current_width = width
	_configure_line(_outer_glow_line, length, width * 8.8 * pulse, Color(1.0, 0.18, 0.01, 0.34), "outer")
	_configure_line(_glow_line, length, width * 5.8 * pulse, Color(1.0, 0.35, 0.02, 0.92), "glow")
	_configure_line(_core_line, length, width * 1.18 * pulse, Color(1.0, 0.46, 0.02, 1.0), "core")
	_configure_line(_hot_line, length, width * 0.18 * pulse, Color(1.0, 0.92, 0.26, 1.0), "hot")
	_configure_collision(length, width * 1.15)
	_configure_particles(length, width * pulse)


func _configure_line(line: Line2D, length: float, width: float, color: Color, profile: String) -> void:
	if line == null:
		return
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])
	line.width = width
	line.default_color = color
	line.antialiased = true
	if profile in ["core", "hot"]:
		line.gradient = null
		line.width_curve = null
	else:
		line.gradient = _line_gradient(color, profile)
		line.width_curve = _width_curve(profile)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.round_precision = 16
	line.z_index = _line_z_index(profile)
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
		_beam_particles.amount = 180
		_beam_particles.lifetime = 0.22
		_beam_particles.preprocess = 0.22
		_beam_particles.randomness = 0.62
		_beam_particles.fixed_fps = 30
		_beam_particles.visibility_rect = Rect2(Vector2(-length * 0.55, -width * 8.0), Vector2(length * 1.1, width * 16.0))
		_beam_particles.material = _additive_material()
		_beam_particles.process_material = _make_beam_material(length, width)
	if _muzzle_particles:
		_muzzle_particles.position = Vector2.ZERO
		_muzzle_particles.amount = 78
		_muzzle_particles.lifetime = 0.28
		_muzzle_particles.preprocess = 0.05
		_muzzle_particles.randomness = 0.70
		_muzzle_particles.fixed_fps = 30
		_muzzle_particles.visibility_rect = Rect2(Vector2(-width * 4.0, -width * 4.0), Vector2(width * 12.0, width * 8.0))
		_muzzle_particles.material = _additive_material()
		_muzzle_particles.process_material = _make_muzzle_material(width)
	if _side_particles:
		_side_particles.position = Vector2(width * 0.9, 0.0)
		_side_particles.amount = 48
		_side_particles.lifetime = 0.20
		_side_particles.preprocess = 0.03
		_side_particles.randomness = 0.75
		_side_particles.fixed_fps = 30
		_side_particles.visibility_rect = Rect2(Vector2(-width * 8.0, -width * 8.0), Vector2(width * 16.0, width * 16.0))
		_side_particles.material = _additive_material()
		_side_particles.process_material = _make_side_spark_material(width)
	if _impact_particles:
		_impact_particles.position = Vector2(length, 0.0)
		_impact_particles.amount = 68
		_impact_particles.lifetime = 0.24
		_impact_particles.preprocess = 0.04
		_impact_particles.randomness = 0.62
		_impact_particles.fixed_fps = 30
		_impact_particles.visibility_rect = Rect2(Vector2(-width * 8.0, -width * 8.0), Vector2.ONE * width * 16.0)
		_impact_particles.material = _additive_material()
		_impact_particles.process_material = _make_impact_material(width)
		_impact_particles.emitting = _hit_body != null and is_instance_valid(_hit_body)


func _make_beam_material(length: float, width: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(length * 0.5, width * 0.58, 1.0)
	particle_material.direction = Vector3(1.0, 0.0, 0.0)
	particle_material.spread = 4.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = DisplaySettings.scale_value(34.0)
	particle_material.initial_velocity_max = DisplaySettings.scale_value(118.0)
	particle_material.scale_min = DisplaySettings.scale_factor() * 0.50
	particle_material.scale_max = DisplaySettings.scale_factor() * 1.85
	particle_material.color = Color(1.0, 0.66, 0.10, 0.58)
	particle_material.color_ramp = _make_laser_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material


func _make_muzzle_material(width: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = width * 2.15
	particle_material.direction = Vector3(1.0, 0.0, 0.0)
	particle_material.spread = 42.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = DisplaySettings.scale_value(145.0)
	particle_material.initial_velocity_max = DisplaySettings.scale_value(380.0)
	particle_material.scale_min = DisplaySettings.scale_factor() * 1.0
	particle_material.scale_max = DisplaySettings.scale_factor() * 3.2
	particle_material.color = Color(1.0, 0.78, 0.18, 0.92)
	particle_material.color_ramp = _make_hot_laser_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material


func _make_side_spark_material(width: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = width * 1.15
	particle_material.direction = Vector3(0.0, 1.0, 0.0)
	particle_material.spread = 150.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = DisplaySettings.scale_value(80.0)
	particle_material.initial_velocity_max = DisplaySettings.scale_value(240.0)
	particle_material.scale_min = DisplaySettings.scale_factor() * 0.95
	particle_material.scale_max = DisplaySettings.scale_factor() * 2.45
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.color = Color(1.0, 0.30, 0.08, 0.88)
	particle_material.color_ramp = _make_hot_laser_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material


func _make_impact_material(width: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = width * 1.85
	particle_material.direction = Vector3(-1.0, 0.0, 0.0)
	particle_material.spread = 130.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = DisplaySettings.scale_value(115.0)
	particle_material.initial_velocity_max = DisplaySettings.scale_value(320.0)
	particle_material.scale_min = DisplaySettings.scale_factor() * 0.85
	particle_material.scale_max = DisplaySettings.scale_factor() * 2.85
	particle_material.color = Color(1.0, 0.58, 0.10, 0.94)
	particle_material.color_ramp = _make_hot_laser_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material


func _make_laser_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.36, 0.02, 0.0))
	gradient.set_color(1, Color(1.0, 0.18, 0.02, 0.0))
	gradient.add_point(0.10, Color(1.0, 0.95, 0.48, 0.96))
	gradient.add_point(0.42, Color(1.0, 0.62, 0.05, 0.78))
	gradient.add_point(0.76, Color(1.0, 0.30, 0.04, 0.22))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _make_hot_laser_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.20, 0.02, 0.0))
	gradient.set_color(1, Color(1.0, 0.08, 0.02, 0.0))
	gradient.add_point(0.10, Color(1.0, 0.98, 0.52, 1.0))
	gradient.add_point(0.36, Color(1.0, 0.45, 0.06, 0.88))
	gradient.add_point(0.70, Color(1.0, 0.16, 0.04, 0.18))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _line_gradient(color: Color, profile: String) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var start_alpha := 0.95 if profile in ["core", "hot"] else 0.64
	var end_alpha := 0.45 if profile in ["core", "hot"] else 0.16
	gradient.add_point(0.02, Color(color.r, color.g, color.b, color.a * start_alpha))
	gradient.add_point(0.11, color)
	gradient.add_point(0.68, color)
	gradient.add_point(0.92, Color(color.r, color.g, color.b, color.a * end_alpha))
	return gradient


func _width_curve(profile: String) -> Curve:
	var curve := Curve.new()
	match profile:
		"outer":
			curve.add_point(Vector2(0.0, 1.35))
			curve.add_point(Vector2(0.10, 0.78))
			curve.add_point(Vector2(0.55, 0.50))
			curve.add_point(Vector2(1.0, 0.95))
		"glow":
			curve.add_point(Vector2(0.0, 1.28))
			curve.add_point(Vector2(0.14, 0.80))
			curve.add_point(Vector2(0.58, 0.62))
			curve.add_point(Vector2(1.0, 0.92))
		"hot":
			curve.add_point(Vector2(0.0, 1.08))
			curve.add_point(Vector2(0.22, 0.72))
			curve.add_point(Vector2(0.74, 0.54))
			curve.add_point(Vector2(1.0, 0.62))
		_:
			curve.add_point(Vector2(0.0, 1.16))
			curve.add_point(Vector2(0.18, 0.78))
			curve.add_point(Vector2(0.68, 0.62))
			curve.add_point(Vector2(1.0, 0.78))
	return curve


func _line_z_index(profile: String) -> int:
	match profile:
		"outer":
			return 0
		"glow":
			return 1
		"core":
			return 2
		"hot":
			return 3
	return 0


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
	for particles in [_beam_particles, _muzzle_particles, _side_particles]:
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
