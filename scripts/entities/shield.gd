extends Area2D
class_name ShieldBubble

var target: PlayerShip
var health := 100.0
var max_health := 100.0
var retired := false
var _base_radius := 87.0
var _pulse := 0.0
var _hit_flash_timer := 0.0
var _particle_texture: Texture2D
const HIT_FLASH_DURATION := 0.18
const OUTER_RING_COLOR := Color(1.0, 0.78, 0.10, 0.68)
const INNER_RING_COLOR := Color(1.0, 0.96, 0.42, 0.54)
const HIT_RING_COLOR := Color(1.0, 0.16, 0.08, 0.92)

@onready var _ring: Line2D = get_node_or_null("ShieldRing") as Line2D
@onready var _inner_ring: Line2D = get_node_or_null("InnerRing") as Line2D
@onready var _aura_particles: GPUParticles2D = get_node_or_null("AuraParticles") as GPUParticles2D
@onready var _core_particles: GPUParticles2D = get_node_or_null("CoreParticles") as GPUParticles2D
@onready var _spark_particles: GPUParticles2D = get_node_or_null("SparkParticles") as GPUParticles2D
@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

func configure(player: PlayerShip) -> void:
	target = player
	reset_health()
	collision_layer = 32
	collision_mask = 2 | 8
	monitoring = true
	monitorable = true
	z_index = 48
	_ensure_nodes()
	_layout_effect()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func reset_health() -> void:
	health = max_health
	_set_shield_state(health, max_health)

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
	_damage_shield(bullet.damage)

func _on_area_entered(area: Area2D) -> void:
	if retired or target == null:
		return
	if area is CombatBody:
		var body := area as CombatBody
		if body.dead or body.team == target.team:
			return
		var shield_damage := body.health
		body.take_damage(health)
		_damage_shield(shield_damage)

func _damage_shield(amount: float) -> void:
	health -= amount
	_set_shield_state(health, max_health)
	_play_shield_sfx()
	_hit_flash_timer = HIT_FLASH_DURATION
	_restart_hit_sparks()
	if health <= 0:
		call_deferred("_retire")

func _play_shield_sfx() -> void:
	var audio_bus := get_node_or_null("/root/AudioBus")
	if audio_bus and audio_bus.has_method("play_sfx"):
		audio_bus.call("play_sfx", "shield")

func _retire() -> void:
	if is_queued_for_deletion() or retired:
		return
	retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	_clear_shield_state()
	visible = false
	set_process(false)
	set_physics_process(false)

func _set_shield_state(value: float, max_value: float) -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("set_shield"):
		game_data.call("set_shield", value, max_value)

func _clear_shield_state() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("clear_shield"):
		game_data.call("clear_shield")

func _scale_value(value: float) -> float:
	var display_settings := get_node_or_null("/root/DisplaySettings")
	if display_settings and display_settings.has_method("scale_value"):
		return float(display_settings.call("scale_value", value))
	return value

func _scale_factor() -> float:
	var display_settings := get_node_or_null("/root/DisplaySettings")
	if display_settings and display_settings.has_method("scale_factor"):
		return float(display_settings.call("scale_factor"))
	return 1.0

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
	if _core_particles == null:
		_core_particles = GPUParticles2D.new()
		_core_particles.name = "CoreParticles"
		add_child(_core_particles)
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
	var radius := _scale_value(_base_radius)
	var visual_radius := _scale_value(70.0)
	if _collision and _collision.shape is CircleShape2D:
		(_collision.shape as CircleShape2D).radius = radius
		_collision.disabled = false
	_configure_ring(_ring, visual_radius, _scale_value(3.2), OUTER_RING_COLOR)
	_configure_ring(_inner_ring, visual_radius * 0.82, _scale_value(1.8), INNER_RING_COLOR)
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
	var dot_texture := _shield_particle_texture()
	if _aura_particles:
		_aura_particles.texture = dot_texture
		_aura_particles.amount = 48
		_aura_particles.lifetime = 1.20
		_aura_particles.preprocess = 1.20
		_aura_particles.randomness = 0.82
		_aura_particles.fixed_fps = 30
		_aura_particles.visibility_rect = Rect2(Vector2(-radius * 1.65, -radius * 1.65), Vector2.ONE * radius * 3.3)
		_aura_particles.material = _soft_particle_material()
		_aura_particles.process_material = _make_aura_material(radius)
		_aura_particles.emitting = true
	if _core_particles:
		_core_particles.texture = dot_texture
		_core_particles.amount = 18
		_core_particles.lifetime = 0.85
		_core_particles.preprocess = 0.85
		_core_particles.randomness = 0.86
		_core_particles.fixed_fps = 30
		_core_particles.visibility_rect = Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2.0)
		_core_particles.material = _soft_particle_material()
		_core_particles.process_material = _make_core_material(radius)
		_core_particles.emitting = true
	if _spark_particles:
		_spark_particles.texture = dot_texture
		_spark_particles.amount = 40
		_spark_particles.lifetime = 0.34
		_spark_particles.one_shot = true
		_spark_particles.explosiveness = 0.9
		_spark_particles.randomness = 0.5
		_spark_particles.visibility_rect = Rect2(Vector2(-radius * 1.5, -radius * 1.5), Vector2.ONE * radius * 3.0)
		_spark_particles.material = _additive_material()
		_spark_particles.process_material = _make_spark_material(radius)

func _make_aura_material(radius: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = radius
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = _scale_value(7.0)
	particle_material.initial_velocity_max = _scale_value(32.0)
	particle_material.scale_min = _scale_factor() * 0.24
	particle_material.scale_max = _scale_factor() * 0.55
	particle_material.angular_velocity_min = -70.0
	particle_material.angular_velocity_max = 70.0
	particle_material.color = Color(1.0, 0.78, 0.12, 0.10)
	particle_material.color_ramp = _make_aura_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material

func _make_core_material(radius: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = radius * 0.68
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = _scale_value(3.0)
	particle_material.initial_velocity_max = _scale_value(18.0)
	particle_material.scale_min = _scale_factor() * 0.20
	particle_material.scale_max = _scale_factor() * 0.42
	particle_material.angular_velocity_min = -120.0
	particle_material.angular_velocity_max = 120.0
	particle_material.color = Color(1.0, 0.90, 0.20, 0.08)
	particle_material.color_ramp = _make_core_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material

func _make_spark_material(radius: float) -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = radius * 0.92
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = _scale_value(85.0)
	particle_material.initial_velocity_max = _scale_value(230.0)
	particle_material.scale_min = _scale_factor() * 0.8
	particle_material.scale_max = _scale_factor() * 2.8
	particle_material.color = Color(1.0, 0.32, 0.18, 0.8)
	particle_material.color_ramp = _make_spark_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material

func _make_aura_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.44, 0.0, 0.0))
	gradient.set_color(1, Color(1.0, 0.30, 0.0, 0.0))
	gradient.add_point(0.16, Color(1.0, 0.94, 0.34, 0.11))
	gradient.add_point(0.50, Color(1.0, 0.72, 0.08, 0.06))
	gradient.add_point(0.82, Color(1.0, 0.96, 0.48, 0.09))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _make_core_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.50, 0.02, 0.0))
	gradient.set_color(1, Color(1.0, 0.46, 0.0, 0.0))
	gradient.add_point(0.20, Color(1.0, 1.0, 0.52, 0.10))
	gradient.add_point(0.62, Color(1.0, 0.70, 0.06, 0.06))
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

func _soft_particle_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return material

func _shield_particle_texture() -> Texture2D:
	if _particle_texture:
		return _particle_texture
	var image := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	var center := Vector2(2.0, 2.0)
	for y in 5:
		for x in 5:
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var alpha := clampf(1.0 - distance / 2.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_particle_texture = ImageTexture.create_from_image(image)
	return _particle_texture

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
