extends Area2D
class_name ShieldBubble

var target: PlayerShip
var health := 100.0
var retired := false
var _base_radius := 87.0
var _pulse := 0.0
var _hit_flash_timer := 0.0
const HIT_FLASH_DURATION := 0.18
const OUTER_RING_COLOR := Color(0.26, 0.96, 1.0, 0.62)
const INNER_RING_COLOR := Color(0.74, 1.0, 1.0, 0.46)
const HIT_RING_COLOR := Color(1.0, 0.16, 0.08, 0.92)

@onready var _ring: Line2D = get_node_or_null("ShieldRing") as Line2D
@onready var _inner_ring: Line2D = get_node_or_null("InnerRing") as Line2D
@onready var _aura_particles: GPUParticles2D = get_node_or_null("AuraParticles") as GPUParticles2D
@onready var _spark_particles: GPUParticles2D = get_node_or_null("SparkParticles") as GPUParticles2D
@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

func configure(player: PlayerShip) -> void:
	target = player
	collision_layer = 32
	collision_mask = 2 | 8
	z_index = 48
	_ensure_nodes()
	_layout_effect()

func _process(delta: float) -> void:
	if target == null or target.dead:
		call_deferred("_retire")
	else:
		global_position = target.global_position
		_pulse += delta * 2.8
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
		var hit_strength := _hit_flash_timer / HIT_FLASH_DURATION
		if _ring:
			_ring.rotation += delta * 0.55
			_ring.modulate.a = 0.72 + sin(_pulse) * 0.12
			_ring.default_color = OUTER_RING_COLOR.lerp(HIT_RING_COLOR, hit_strength)
		if _inner_ring:
			_inner_ring.rotation -= delta * 0.85
			_inner_ring.scale = Vector2.ONE * (0.96 + sin(_pulse * 1.4) * 0.035)
			_inner_ring.default_color = INNER_RING_COLOR.lerp(HIT_RING_COLOR, hit_strength)
		modulate = Color.WHITE.lerp(Color(1.0, 0.28, 0.18, 1.0), hit_strength * 0.85)

func reflect_bullet(bullet: SpaceBullet) -> void:
	if bullet.shooter_team == "player":
		return
	bullet.shooter_team = "player"
	bullet.velocity *= -1.15
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 32
	health -= bullet.damage
	AudioBus.play_sfx("shield")
	_hit_flash_timer = HIT_FLASH_DURATION
	_restart_hit_sparks()
	if health <= 0:
		call_deferred("_retire")

func _retire() -> void:
	if is_queued_for_deletion() or retired:
		return
	retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	visible = false
	set_process(false)
	set_physics_process(false)

func _ensure_nodes() -> void:
	if _ring == null:
		_ring = Line2D.new()
		_ring.name = "ShieldRing"
		add_child(_ring)
	if _inner_ring == null:
		_inner_ring = Line2D.new()
		_inner_ring.name = "InnerRing"
		add_child(_inner_ring)
	if _aura_particles == null:
		_aura_particles = GPUParticles2D.new()
		_aura_particles.name = "AuraParticles"
		add_child(_aura_particles)
	if _spark_particles == null:
		_spark_particles = GPUParticles2D.new()
		_spark_particles.name = "SparkParticles"
		add_child(_spark_particles)
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	if _collision.shape == null or not _collision.shape is CircleShape2D:
		_collision.shape = CircleShape2D.new()

func _layout_effect() -> void:
	var radius := DisplaySettings.scale_value(_base_radius)
	var visual_radius := DisplaySettings.scale_value(70.0)
	if _collision and _collision.shape is CircleShape2D:
		(_collision.shape as CircleShape2D).radius = radius
		_collision.disabled = false
	_configure_ring(_ring, visual_radius, DisplaySettings.scale_value(3.2), OUTER_RING_COLOR)
	_configure_ring(_inner_ring, visual_radius * 0.82, DisplaySettings.scale_value(1.8), INNER_RING_COLOR)
	_configure_particles(visual_radius)

func _configure_ring(ring: Line2D, radius: float, width: float, color: Color) -> void:
	if ring == null:
		return
	var points := _circle_points(72, radius)
	points.append(points[0])
	ring.points = points
	ring.width = width
	ring.default_color = color
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.joint_mode = Line2D.LINE_JOINT_ROUND
	if ring.material == null:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ring.material = material

func _configure_particles(radius: float) -> void:
	if _aura_particles:
		_aura_particles.amount = 140
		_aura_particles.lifetime = 1.45
		_aura_particles.preprocess = 1.45
		_aura_particles.randomness = 0.78
		_aura_particles.fixed_fps = 30
		_aura_particles.visibility_rect = Rect2(Vector2(-radius * 1.65, -radius * 1.65), Vector2.ONE * radius * 3.3)
		_aura_particles.material = _additive_material()
		_aura_particles.process_material = _make_aura_material(radius)
		_aura_particles.emitting = true
	if _spark_particles:
		_spark_particles.amount = 40
		_spark_particles.lifetime = 0.34
		_spark_particles.one_shot = true
		_spark_particles.explosiveness = 0.9
		_spark_particles.randomness = 0.5
		_spark_particles.visibility_rect = Rect2(Vector2(-radius * 1.5, -radius * 1.5), Vector2.ONE * radius * 3.0)
		_spark_particles.material = _additive_material()
		_spark_particles.process_material = _make_spark_material(radius)

func _make_aura_material(radius: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(6.0)
	material.initial_velocity_max = DisplaySettings.scale_value(34.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.7
	material.scale_max = DisplaySettings.scale_factor() * 2.4
	material.angular_velocity_min = -55.0
	material.angular_velocity_max = 55.0
	material.color = Color(0.28, 0.95, 1.0, 0.30)
	material.color_ramp = _make_aura_ramp()
	material.particle_flag_disable_z = true
	return material

func _make_spark_material(radius: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius * 0.92
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = DisplaySettings.scale_value(85.0)
	material.initial_velocity_max = DisplaySettings.scale_value(230.0)
	material.scale_min = DisplaySettings.scale_factor() * 0.8
	material.scale_max = DisplaySettings.scale_factor() * 2.8
	material.color = Color(1.0, 0.32, 0.18, 0.8)
	material.color_ramp = _make_spark_ramp()
	material.particle_flag_disable_z = true
	return material

func _make_aura_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.1, 0.6, 1.0, 0.0))
	gradient.set_color(1, Color(0.1, 0.9, 1.0, 0.0))
	gradient.add_point(0.18, Color(0.55, 1.0, 1.0, 0.42))
	gradient.add_point(0.50, Color(0.20, 0.75, 1.0, 0.18))
	gradient.add_point(0.82, Color(0.85, 1.0, 1.0, 0.36))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _make_spark_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.2, 0.12, 0.0))
	gradient.set_color(1, Color(0.2, 0.9, 1.0, 0.0))
	gradient.add_point(0.14, Color(1.0, 0.45, 0.22, 0.95))
	gradient.add_point(0.55, Color(0.42, 1.0, 1.0, 0.62))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

func _restart_hit_sparks() -> void:
	if _spark_particles == null:
		return
	_spark_particles.emitting = true
	_spark_particles.restart()

func _circle_points(count: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
