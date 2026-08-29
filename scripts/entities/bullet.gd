extends Area2D
class_name SpaceBullet

@export var bullet_type := "Bullet1"
@export var use_scene_template := false

var shooter_team := "player"
var velocity := Vector2.ZERO
var damage := 10.0
var life_time := 4.0
var pierce := false
var homing := false
var homing_range := 0.0
var homing_direct := false
var homing_delay_timer := 0.0
var base_speed := 0.0
var visual_angle_offset := PI / 2.0
var damage_tick_interval := 0.0
var damage_tick_timer := 0.0
var spin := 0.0
var spin_angle := 0.0
var curve_rate := 0.0
var curve_direction := 1.0
var retired := false
var hit_spark_timer := 0.0
var _homing_target: CombatBody = null
var _homing_target_locked := false
var _template_node_states: Dictionary = {}
var _template_shape_states: Dictionary = {}
var _level_light_texture: Texture2D
var _laser_particle_texture: Texture2D
var _laser_direction := Vector2.ZERO
var _laser_start_distance := 0.0
var _laser_end_distance := 0.0
var _laser_max_end_distance := 0.0
var _laser_cast_duration := 0.0
var _laser_cast_elapsed := 0.0
var _follow_owner: Node2D = null
var _follow_offset := Vector2.ZERO
var _laser_has_collision_endpoint := false

const DAMAGE_VARIANCE := 0.10
const BulletHitSparkScene := preload("res://scenes/components/bullet_hit_spark.tscn")
const BULLET_SCENE_PATHS := {
	"Bullet1": "res://scenes/entities/bullets/bullet_1.tscn",
	"Bullet2": "res://scenes/entities/bullets/bullet_2.tscn",
	"BulletArrow": "res://scenes/entities/bullets/bullet_arrow.tscn",
	"BulletMissile": "res://scenes/entities/bullets/bullet_missile.tscn",
	"BulletLaser": "res://scenes/entities/bullets/bullet_laser.tscn",
	"BulletFire": "res://scenes/entities/bullets/bullet_fire.tscn",
	"BulletYue": "res://scenes/entities/bullets/bullet_yue.tscn",
	"BulletPhaseShard": "res://scenes/entities/bullets/bullet_phase_shard.tscn",
	"Bullet3": "res://scenes/entities/bullets/bullet_3.tscn",
	"FollowBullet": "res://scenes/entities/bullets/follow_bullet.tscn",
}

static func create(type_name: String) -> SpaceBullet:
	var scene_path := String(BULLET_SCENE_PATHS.get(type_name, BULLET_SCENE_PATHS["Bullet1"]))
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return SpaceBullet.new()
	var bullet := scene.instantiate() as SpaceBullet
	return bullet if bullet != null else SpaceBullet.new()

func setup(type_name: String, team: String, pos: Vector2, direction: Vector2, overrides := {}) -> void:
	bullet_type = type_name
	shooter_team = team
	global_position = pos
	var safe_direction := _safe_direction(direction)
	var info := bullet_info(type_name)
	for key in overrides.keys():
		info[key] = overrides[key]
	damage = float(info.damage)
	if team == "player":
		damage *= GameData.weapon_damage_multiplier(type_name)
	base_speed = DisplaySettings.scale_value(float(info.speed))
	velocity = safe_direction * base_speed
	life_time = float(info.life)
	pierce = bool(info.pierce)
	homing = bool(info.homing)
	homing_range = DisplaySettings.scale_value(float(info.get("homing_range", 0.0)))
	homing_direct = bool(info.get("homing_direct", false))
	homing_delay_timer = float(info.get("homing_delay", 0.0))
	_homing_target = null
	_homing_target_locked = false
	visual_angle_offset = float(info.get("visual_angle_offset", PI / 2.0))
	rotation = _rotation_for_direction(safe_direction)
	damage_tick_interval = float(info.get("tick_interval", 0.0))
	damage_tick_timer = damage_tick_interval
	spin = float(info.spin)
	spin_angle = 0.0
	curve_rate = float(info.get("curve_rate", 0.0))
	curve_direction = float(info.get("curve_direction", 1.0))
	collision_layer = 4 if team == "player" else 8
	collision_mask = 2 | 32 if team == "player" else 1 | 32
	_follow_owner = overrides.get("follow_owner") as Node2D
	_follow_offset = overrides.get("follow_offset", Vector2.ZERO)
	_make_visual(info)
	if bullet_type == "BulletLaser":
		_laser_direction = safe_direction
		_update_laser_endpoint(0.0)
	_apply_weapon_level_effect(info)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if homing and is_inside_tree():
		_lock_homing_target_once()

static func bullet_info(type_name: String) -> Dictionary:
	var map := {
		"Bullet1": {"speed": 1080.0, "damage": 5.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.58, "radius": 7.0, "height": 30.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"Bullet2": {"speed": 540.0, "damage": 5.0, "interval": 2.0, "life": 4.0, "texture": "res://assets/sprites/bullet4.png", "scale": 0.58, "radius": 10.0, "height": 32.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot2"},
		"BulletArrow": {"speed": 1080.0, "damage": 3.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/WyvernHornBow.png", "scale": 0.30, "radius": 16.0, "height": 48.0, "pierce": false, "homing": false, "spin": 0.0, "visual_angle_offset": PI / 4.0, "sfx": "arrow"},
		"BulletMissile": {"speed": 540.0, "damage": 50.0, "interval": 1.5, "life": 5.0, "texture": "res://assets/sprites/spr_missile.png", "scale": 0.70, "radius": 10.0, "height": 42.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "missile"},
		"BulletLaser": {"speed": 0.0, "damage": 1.0, "interval": 2.0, "life": 1.5, "tick_interval": 0.08, "texture": "res://assets/sprites/bosslaser.png", "scale": 1.0, "radius": 18.0, "height": 810.0, "length": 1240.0, "width": 20.0, "pierce": true, "homing": false, "spin": 0.0, "visual_angle_offset": 0.0, "cast_time": 0.18, "sfx": "laser"},
		"BulletFire": {"speed": 540.0, "damage": 10.0, "interval": 1.0, "life": 3.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(416, 144, 16, 17), Rect2(432, 144, 16, 17), Rect2(448, 144, 16, 17), Rect2(464, 144, 16, 17)], "scale": 1.35, "radius": 8.0, "height": 22.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "bullet_fire"},
		"BulletYue": {"speed": 540.0, "damage": 6.0, "interval": 0.2, "life": 3.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(576, 16, 16, 17), Rect2(592, 16, 16, 17), Rect2(608, 16, 16, 17), Rect2(624, 16, 16, 17)], "scale": 1.35, "radius": 8.0, "height": 24.0, "pierce": false, "homing": false, "spin": 8.0, "sfx": "bullet_yue"},
		"BulletPhaseShard": {"speed": 640.0, "damage": 7.0, "interval": 1.55, "life": 4.0, "texture": "res://assets/sprites/bullet_phase_shard.png", "scale": 0.44, "radius": 7.0, "height": 28.0, "pierce": false, "homing": false, "spin": 5.4, "curve_rate": 0.0, "curve_direction": 1.0, "visual_angle_offset": PI / 2.0, "sfx": "bullet_yue"},
		"Bullet3": {"speed": 1080.0, "damage": 5.0, "interval": 0.18, "life": 3.0, "texture": "res://assets/sprites/bullet6.png", "scale": 0.50, "radius": 8.0, "height": 34.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"FollowBullet": {"speed": 1080.0, "damage": 2.0, "interval": 0.1, "life": 4.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(96, 48, 16, 16), Rect2(112, 48, 16, 16), Rect2(128, 48, 16, 16), Rect2(144, 48, 16, 16)], "scale": 1.2, "radius": 8.0, "height": 22.0, "pierce": false, "homing": true, "homing_range": 648.0, "homing_direct": true, "homing_delay": 0.14, "visual_angle_offset": -PI / 4.0, "spin": 0.0, "sfx": "shoot"},
	}
	return map.get(type_name, map["Bullet1"])

static func roll_damage(base_damage: float) -> float:
	return maxf(0.0, base_damage * randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE))

func _ready() -> void:
	if homing and not _homing_target_locked:
		_lock_homing_target_once()

func _physics_process(delta: float) -> void:
	if retired:
		return
	if _follow_owner != null:
		if not is_instance_valid(_follow_owner) or _follow_owner.is_queued_for_deletion():
			call_deferred("_retire")
			return
		global_position = _follow_owner.to_global(_follow_offset)
	_sync_weapon_level_particles()
	life_time -= delta
	hit_spark_timer = maxf(0.0, hit_spark_timer - delta)
	if life_time <= 0:
		call_deferred("_retire")
		return
	if homing:
		if not _homing_target_locked:
			_lock_homing_target_once()
		if homing_delay_timer > 0.0:
			homing_delay_timer -= delta
		else:
			var target := _locked_homing_target()
			if target:
				var target_delta := target.tracking_position() - global_position
				if target_delta.length_squared() > 1.0:
					var current_speed := velocity.length()
					if current_speed <= 0.0:
						current_speed = base_speed
					var desired := target_delta.normalized() * current_speed
					velocity = desired if homing_direct else velocity.lerp(desired, 4.0 * delta)
	if velocity.is_zero_approx() and base_speed > 0.0:
		velocity = Vector2.UP * base_speed
	if velocity != Vector2.ZERO:
		if not is_zero_approx(curve_rate):
			velocity = velocity.rotated(curve_rate * curve_direction * delta)
		var next_position := global_position + velocity * delta
		if _sweep_motion(global_position, next_position):
			return
		global_position = next_position
		if spin != 0.0:
			spin_angle += spin * delta
		rotation = _rotation_for_direction(velocity)
		_sync_weapon_level_particles()
	elif spin != 0.0:
		rotation += spin * delta
		_sync_weapon_level_particles()
	if damage_tick_interval > 0.0:
		if bullet_type == "BulletLaser":
			_update_laser_endpoint(delta)
		damage_tick_timer -= delta
		if damage_tick_timer <= 0.0:
			damage_tick_timer = damage_tick_interval
			_damage_overlapping_targets()

func _on_area_entered(area: Area2D) -> void:
	if retired:
		return
	if area.has_method("reflect_bullet"):
		area.reflect_bullet(self)
		return
	if area is CombatBody and area.team != shooter_team:
		var body := area as CombatBody
		if body.dead:
			return
		var hit_position := body.closest_collision_point(global_position)
		_spawn_hit_spark(hit_position)
		body.take_damage(roll_damage(damage), hit_position, true)
		if not pierce:
			_retire()

func _sweep_motion(from_position: Vector2, to_position: Vector2) -> bool:
	if from_position.distance_squared_to(to_position) <= 1.0:
		return false
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position)
	query.collision_mask = collision_mask
	if shooter_team == "player":
		query.collision_mask &= ~32
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider := result.get("collider") as Object
	if collider == null:
		return false
	var hit_position := result.get("position") as Vector2
	global_position = hit_position
	if collider.has_method("reflect_bullet") and shooter_team != "player":
		collider.call("reflect_bullet", self)
		return true
	if collider is CombatBody:
		var body := collider as CombatBody
		if body.dead or body.team == shooter_team:
			return false
		_spawn_hit_spark(hit_position)
		body.take_damage(roll_damage(damage), hit_position, true)
		if not pierce:
			_retire()
		return true
	return false

func _retire() -> void:
	if is_queued_for_deletion() or retired:
		return
	retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	if bullet_type == "BulletMissile":
		_spawn_missile_burst()
	var level_particles := get_node_or_null("BulletLevelParticles") as CPUParticles2D
	if level_particles:
		level_particles.emitting = false
		level_particles.visible = false
	visible = false
	set_process(false)
	set_physics_process(false)
	call_deferred("queue_free")

func _make_visual(info: Dictionary) -> void:
	if use_scene_template:
		_apply_scene_template()
		if bullet_type == "BulletLaser":
			_configure_laser_effect(info)
		return
	var animated := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if info.has("frames"):
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.queue_free()
		if animated == null:
			animated = AnimatedSprite2D.new()
			animated.name = "AnimatedSprite2D"
			add_child(animated)
		var frames := SpriteFrames.new()
		frames.add_animation("fly")
		frames.set_animation_speed("fly", 12.0)
		frames.set_animation_loop("fly", true)
		for frame_rect in info.frames:
			frames.add_frame("fly", _make_atlas_texture(String(info.texture), frame_rect))
		animated.sprite_frames = frames
		animated.animation = "fly"
		animated.scale = Vector2.ONE * float(info.scale) * DisplaySettings.scale_factor()
		animated.modulate = _visual_modulate(info)
		animated.play()
	elif get_node_or_null("Sprite2D") == null:
		var new_sprite := Sprite2D.new()
		new_sprite.name = "Sprite2D"
		add_child(new_sprite)
	if not info.has("frames"):
		if animated:
			animated.queue_free()
		var sprite := get_node("Sprite2D") as Sprite2D
		sprite.texture = _make_texture(info)
		sprite.scale = Vector2.ONE * float(info.scale) * DisplaySettings.scale_factor()
		sprite.modulate = _visual_modulate(info)
		sprite.offset = Vector2.ZERO
		if bullet_type == "BulletLaser":
			sprite.scale = Vector2(0.24, 1.05) * DisplaySettings.scale_factor()
			if sprite.texture:
				sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	if bullet_type == "BulletMissile":
		_ensure_missile_trail()
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = CapsuleShape2D.new()
		add_child(shape)
	var collision := get_node("CollisionShape2D") as CollisionShape2D
	var capsule := collision.shape as CapsuleShape2D
	if bullet_type == "BulletLaser":
		capsule.radius = DisplaySettings.scale_value(float(info.radius))
		capsule.height = DisplaySettings.scale_value(float(info.height))
		collision.position = Vector2(0, -capsule.height * 0.5)
	else:
		capsule.radius = DisplaySettings.scale_value(float(info.radius))
		capsule.height = DisplaySettings.scale_value(float(info.height))
		collision.position = Vector2.ZERO

func _configure_laser_effect(info: Dictionary) -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.visible = false
	var length := DisplaySettings.scale_value(float(info.get("length", info.get("height", 1240.0))))
	var start_distance := minf(
		DisplaySettings.scale_value(float(info.get("start_distance", 28.0))),
		length - 1.0
	)
	_laser_start_distance = start_distance
	_laser_end_distance = length
	_laser_max_end_distance = length
	_laser_cast_duration = maxf(0.0, float(info.get("cast_time", 0.18)))
	_laser_cast_elapsed = 0.0
	var width := DisplaySettings.scale_value(float(info.get("width", info.get("radius", 18.0))))
	_configure_laser_texture(length, start_distance)
	_configure_laser_line(
		"OuterGlowLine",
		length,
		start_distance,
		width * 2.4,
		Color(1.0, 0.08, 0.03, 0.55),
		"back"
	)
	_configure_laser_line(
		"GlowLine",
		length,
		start_distance,
		width * 1.20,
		Color(1.0, 0.10, 0.04, 1.0),
		"mid"
	)
	_configure_laser_line(
		"CoreLine",
		length,
		start_distance,
		width * 0.42,
		Color(1.0, 0.88, 0.82, 1.0),
		"core"
	)
	_configure_laser_line(
		"HotLine",
		length,
		start_distance,
		width * 0.16,
		Color(1.0, 1.0, 0.96, 1.0),
		"detail"
	)
	_configure_laser_particles(length, start_distance, width)
	_configure_laser_collision(length, start_distance, width)

func _configure_laser_texture(length: float, start_distance: float) -> void:
	var beam_texture := get_node_or_null("BeamTexture") as Sprite2D
	if beam_texture == null:
		return
	beam_texture.visible = false
	beam_texture.position = Vector2((length + start_distance) * 0.5, 0.0)

func _configure_laser_line(
	node_name: String,
	length: float,
	start_distance: float,
	width: float,
	color: Color,
	profile: String
) -> void:
	var line := get_node_or_null(node_name) as Line2D
	if line == null:
		return
	line.points = PackedVector2Array([Vector2(start_distance, 0.0), Vector2(length, 0.0)])
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.round_precision = 16
	line.gradient = null
	line.width_curve = null
	line.material = null
	line.z_index = _laser_line_z_index(profile)

func _configure_laser_particles(length: float, start_distance: float, width: float) -> void:
	var segment_length := maxf(1.0, length - start_distance)
	var width_ratio := maxf(0.55, width / DisplaySettings.scale_value(12.0))
	var beam_particles := get_node_or_null("BeamParticles") as GPUParticles2D
	if beam_particles:
		beam_particles.position = Vector2(start_distance + segment_length * 0.5, 0.0)
		beam_particles.amount = maxi(24, int(round(28.0 + width_ratio * 18.0)))
		beam_particles.lifetime = 0.44
		beam_particles.preprocess = 0.44
		beam_particles.randomness = 1.0
		beam_particles.fixed_fps = 30
		beam_particles.local_coords = true
		beam_particles.visibility_rect = Rect2(
			Vector2(-segment_length * 0.55, -width * 8.0),
			Vector2(segment_length * 1.1, width * 16.0)
		)
		beam_particles.texture = _laser_soft_particle_texture()
		beam_particles.material = _additive_canvas_material()
		beam_particles.process_material = _make_laser_particle_material(segment_length, width)
		beam_particles.z_index = 5
		beam_particles.emitting = true
		beam_particles.restart()
	var muzzle_particles := get_node_or_null("MuzzleParticles") as GPUParticles2D
	if muzzle_particles:
		muzzle_particles.position = Vector2(start_distance, 0.0)
		muzzle_particles.amount = maxi(16, int(round(14.0 + width_ratio * 10.0)))
		muzzle_particles.lifetime = 0.34
		muzzle_particles.preprocess = 0.08
		muzzle_particles.randomness = 0.0
		muzzle_particles.fixed_fps = 30
		muzzle_particles.local_coords = true
		muzzle_particles.visibility_rect = Rect2(
			Vector2(-width * 8.0, -width * 8.0),
			Vector2.ONE * width * 16.0
		)
		muzzle_particles.texture = _laser_soft_particle_texture()
		muzzle_particles.material = _additive_canvas_material()
		muzzle_particles.process_material = _make_laser_muzzle_material(width)
		muzzle_particles.z_index = 6
		muzzle_particles.emitting = true
		muzzle_particles.restart()
	var impact_particles := get_node_or_null("ImpactParticles") as GPUParticles2D
	if impact_particles:
		impact_particles.position = Vector2(length, 0.0)
		impact_particles.amount = maxi(18, int(round(18.0 + width_ratio * 14.0)))
		impact_particles.lifetime = 0.38
		impact_particles.preprocess = 0.12
		impact_particles.randomness = 0.0
		impact_particles.fixed_fps = 30
		impact_particles.local_coords = true
		impact_particles.visibility_rect = Rect2(
			Vector2(-width * 8.0, -width * 8.0),
			Vector2.ONE * width * 16.0
		)
		impact_particles.texture = _laser_soft_particle_texture()
		impact_particles.material = _additive_canvas_material()
		impact_particles.process_material = _make_laser_impact_material(width, _laser_has_collision_endpoint)
		impact_particles.z_index = 6
		impact_particles.emitting = _laser_has_collision_endpoint
		impact_particles.restart()

func _configure_laser_collision(length: float, start_distance: float, width: float) -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	if collision.shape == null or not collision.shape is RectangleShape2D:
		collision.shape = RectangleShape2D.new()
	var rectangle := collision.shape as RectangleShape2D
	var segment_length := maxf(1.0, length - start_distance)
	rectangle.size = Vector2(segment_length, width * 1.25)
	collision.position = Vector2(start_distance + segment_length * 0.5, 0.0)
	collision.disabled = false

func _update_laser_endpoint(delta: float = 0.0) -> void:
	if bullet_type != "BulletLaser":
		return
	var direction := _laser_direction
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(rotation - visual_angle_offset)
	_laser_direction = direction.normalized()
	if _laser_cast_duration > 0.0:
		_laser_cast_elapsed = minf(_laser_cast_elapsed + delta, _laser_cast_duration)
	var cast_ratio := 1.0
	if _laser_cast_duration > 0.0:
		cast_ratio = clampf(_laser_cast_elapsed / _laser_cast_duration, 0.0, 1.0)
	var current_max_end_distance := lerpf(
		_laser_start_distance,
		_laser_max_end_distance,
		cast_ratio
	)
	var origin := global_position + _laser_direction * _laser_start_distance
	var target := global_position + _laser_direction * current_max_end_distance
	var query := PhysicsRayQueryParameters2D.create(origin, target)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	var end_distance := current_max_end_distance
	_laser_has_collision_endpoint = false
	if not result.is_empty():
		var hit_position := result.get("position") as Vector2
		end_distance = _laser_start_distance + origin.distance_to(hit_position)
		_laser_has_collision_endpoint = true
	if is_equal_approx(end_distance, _laser_end_distance):
		return
	_laser_end_distance = end_distance
	var width := 0.0
	var core_line := get_node_or_null("CoreLine") as Line2D
	if core_line:
		width = core_line.width / 0.42
	if width <= 0.0:
		width = DisplaySettings.scale_value(20.0)
	_configure_laser_texture(_laser_end_distance, _laser_start_distance)
	_configure_laser_line(
		"OuterGlowLine",
		_laser_end_distance,
		_laser_start_distance,
		width * 2.4,
		Color(1.0, 0.08, 0.03, 0.55),
		"back"
	)
	_configure_laser_line(
		"GlowLine",
		_laser_end_distance,
		_laser_start_distance,
		width * 1.20,
		Color(1.0, 0.10, 0.04, 1.0),
		"mid"
	)
	_configure_laser_line(
		"CoreLine",
		_laser_end_distance,
		_laser_start_distance,
		width * 0.42,
		Color(1.0, 0.88, 0.82, 1.0),
		"core"
	)
	_configure_laser_line(
		"HotLine",
		_laser_end_distance,
		_laser_start_distance,
		width * 0.16,
		Color(1.0, 1.0, 0.96, 1.0),
		"detail"
	)
	_configure_laser_particles(_laser_end_distance, _laser_start_distance, width)
	_configure_laser_collision(_laser_end_distance, _laser_start_distance, width)

func _laser_shader_material(profile: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _laser_shader()
	material.set_shader_parameter("pulse_speed", 13.0 if profile in ["core", "hot"] else 8.0)
	material.set_shader_parameter("wave_density", 30.0 if profile in ["core", "hot"] else 18.0)
	return material

func _laser_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float pulse_speed = 10.0;
uniform float wave_density = 24.0;

void fragment() {
	vec4 base = COLOR;
	float wave_a = 0.5 + 0.5 * sin(UV.x * wave_density - TIME * pulse_speed);
	float wave_b = 0.5 + 0.5 * sin(UV.x * (wave_density * 0.43) + TIME * pulse_speed * 0.71);
	float ridge = smoothstep(0.38, 1.0, max(wave_a, wave_b * 0.86));
	float edge = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = smoothstep(0.16, 0.78, edge);
	float glow = 0.86 + ridge * 0.56 + core * 0.24;
	COLOR = vec4(base.rgb * glow, base.a * (0.62 + ridge * 0.28 + core * 0.10));
}
"""
	return shader

func _make_laser_particle_material(length: float, width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(length * 0.5, width * 0.30, 1.0)
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 8.0
	material.gravity = Vector3.ZERO
	material.tangential_accel_min = DisplaySettings.scale_value(64.0)
	material.tangential_accel_max = DisplaySettings.scale_value(64.0)
	material.scale_min = DisplaySettings.scale_factor() * maxf(0.26, width * 0.018)
	material.scale_max = DisplaySettings.scale_factor() * maxf(0.58, width * 0.036)
	material.color = Color(1.0, 0.16, 0.04, 0.88)
	material.color_ramp = _laser_particle_ramp()
	material.particle_flag_disable_z = true
	return material

func _make_laser_muzzle_material(width: float) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * 0.42
	material.initial_velocity_min = DisplaySettings.scale_value(96.0)
	material.initial_velocity_max = DisplaySettings.scale_value(96.0)
	material.gravity = Vector3.ZERO
	material.scale_min = DisplaySettings.scale_factor() * maxf(0.42, width * 0.030)
	material.scale_max = DisplaySettings.scale_factor() * maxf(0.42, width * 0.046)
	material.color_ramp = _laser_cast_particle_ramp()
	return material

func _make_laser_impact_material(width: float, collision_active: bool) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = width * (0.60 if collision_active else 0.40)
	material.spread = 50.0
	material.initial_velocity_min = DisplaySettings.scale_value(160.0)
	material.initial_velocity_max = DisplaySettings.scale_value(160.0)
	material.gravity = Vector3.ZERO
	material.scale_min = DisplaySettings.scale_factor() * maxf(0.42, width * 0.032)
	material.scale_max = DisplaySettings.scale_factor() * maxf(0.42, width * 0.052)
	material.color_ramp = _laser_cast_particle_ramp()
	return material

func _laser_cast_particle_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.add_point(0.58, Color(1.0, 0.92, 0.86, 1.0))
	gradient.add_point(1.0, Color(1.0, 0.18, 0.06, 0.0))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 256
	return texture

func _laser_particle_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.04, 0.02, 0.0))
	gradient.set_color(1, Color(1.0, 0.02, 0.01, 0.0))
	gradient.add_point(0.09, Color(1.0, 0.88, 0.46, 1.0))
	gradient.add_point(0.34, Color(1.0, 0.18, 0.04, 0.90))
	gradient.add_point(0.70, Color(1.0, 0.04, 0.01, 0.24))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _laser_line_z_index(profile: String) -> int:
	match profile:
		"back":
			return 0
		"mid":
			return 2
		"core":
			return 3
		"detail":
			return 4
	return 0

func _laser_soft_particle_texture() -> Texture2D:
	if _laser_particle_texture:
		return _laser_particle_texture
	var size := 9
	var center := Vector2(size * 0.5 - 0.5, size * 0.5 - 0.5)
	var radius := float(size) * 0.5
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var alpha := clampf(1.0 - distance / radius, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))
	_laser_particle_texture = ImageTexture.create_from_image(image)
	return _laser_particle_texture

func _additive_canvas_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

func _apply_scene_template() -> void:
	for child in get_children():
		if child is Node2D and not child is CollisionShape2D:
			var visual_node := child as Node2D
			_apply_template_node_state(visual_node)
			if visual_node is AnimatedSprite2D:
				(visual_node as AnimatedSprite2D).play()
	if bullet_type == "BulletMissile":
		_ensure_missile_trail()
	_apply_template_collision()

func _apply_template_node_state(node: Node2D) -> void:
	var key := str(node.get_path())
	if not _template_node_states.has(key):
		_template_node_states[key] = {
			"position": node.position,
			"scale": node.scale,
		}
	var state: Dictionary = _template_node_states[key]
	var scale_factor := DisplaySettings.scale_factor()
	node.position = (state["position"] as Vector2) * scale_factor
	node.scale = (state["scale"] as Vector2) * scale_factor

func _apply_template_collision() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return
	var key := str(collision.get_path())
	if not _template_shape_states.has(key):
		_template_shape_states[key] = {
			"shape": collision.shape.duplicate(),
			"position": collision.position,
		}
		collision.shape = collision.shape.duplicate()
	var state: Dictionary = _template_shape_states[key]
	var base_shape := state["shape"] as Shape2D
	var active_shape := collision.shape
	var scale_factor := DisplaySettings.scale_factor()
	if base_shape is CapsuleShape2D and active_shape is CapsuleShape2D:
		var base_capsule := base_shape as CapsuleShape2D
		var active_capsule := active_shape as CapsuleShape2D
		active_capsule.radius = base_capsule.radius * scale_factor
		active_capsule.height = base_capsule.height * scale_factor
	elif base_shape is CircleShape2D and active_shape is CircleShape2D:
		(active_shape as CircleShape2D).radius = (base_shape as CircleShape2D).radius * scale_factor
	collision.position = (state["position"] as Vector2) * scale_factor
	collision.disabled = false

func _find_target() -> CombatBody:
	var best: CombatBody = null
	var best_dist := INF
	var target_group := "enemy" if shooter_team == "player" else "player"
	for node in get_tree().get_nodes_in_group(target_group):
		if node is CombatBody:
			var body := node as CombatBody
			if body.dead or body.team == shooter_team:
				continue
			if not _is_target_visible_in_camera(body):
				continue
			var target_position := body.tracking_position()
			var dist := global_position.distance_squared_to(target_position)
			if dist <= DisplaySettings.scale_value(12.0) * DisplaySettings.scale_value(12.0):
				continue
			if homing_range > 0.0 and dist > homing_range * homing_range:
				continue
			if dist < best_dist:
				best = body
				best_dist = dist
	return best

func _lock_homing_target_once() -> void:
	if _homing_target_locked:
		return
	_homing_target = _find_target()
	_homing_target_locked = true

func _locked_homing_target() -> CombatBody:
	if not is_instance_valid(_homing_target):
		return null
	if not _homing_target.is_inside_tree() or _homing_target.is_queued_for_deletion():
		return null
	if _homing_target.dead or _homing_target.team == shooter_team:
		return null
	return _homing_target

func _is_target_visible_in_camera(body: CombatBody) -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return true
	var visible_size := get_viewport_rect().size
	if visible_size.x <= 0.0 or visible_size.y <= 0.0:
		visible_size = DisplaySettings.logical_size()
	var screen_pos := viewport.get_canvas_transform() * body.tracking_position()
	var screen_rect := Rect2(Vector2.ZERO, visible_size).grow(DisplaySettings.scale_value(10.0))
	return screen_rect.has_point(screen_pos)

func _safe_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return Vector2.UP
	return direction.normalized()

func _rotation_for_direction(direction: Vector2) -> float:
	var safe_direction := _safe_direction(direction)
	return safe_direction.angle() + visual_angle_offset + spin_angle

func _damage_overlapping_targets() -> void:
	for area in get_overlapping_areas():
		if area is CombatBody and area.team != shooter_team:
			var body := area as CombatBody
			if body.dead:
				continue
			_spawn_hit_spark(body.global_position)
			body.take_damage(roll_damage(damage), body.global_position, true)

func _make_texture(info: Dictionary) -> Texture2D:
	if info.has("region"):
		return _make_atlas_texture(String(info.texture), info.region)
	return load(String(info.texture)) as Texture2D

func _make_atlas_texture(texture_path: String, rect: Rect2) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(texture_path) as Texture2D
	atlas.region = rect
	return atlas

func _visual_modulate(_info: Dictionary) -> Color:
	return Color.WHITE

func _apply_weapon_level_effect(info: Dictionary) -> void:
	if shooter_team != "player":
		return
	var level := GameData.weapon_level(bullet_type)
	if level <= 0:
		_remove_weapon_level_effect()
		return
	var strength := clampf(float(level - 1) / float(GameData.MAX_WEAPON_LEVEL - 1), 0.0, 1.0)
	var color := Color(0.46, 0.96, 1.0, 1.0).lerp(Color(1.0, 0.82, 0.24, 1.0), strength)
	_remove_legacy_weapon_level_effect()

	var particles := get_node_or_null("BulletLevelParticles") as CPUParticles2D
	if particles == null:
		particles = CPUParticles2D.new()
		particles.name = "BulletLevelParticles"
		particles.top_level = true
		particles.z_as_relative = false
		particles.z_index = 48
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		particles.material = material
		add_child(particles)
	particles.texture = _make_level_light_texture()
	particles.emitting = true
	particles.amount = int(round(lerpf(5.0, 16.0, strength)))
	particles.lifetime = lerpf(0.055, 0.105, strength)
	particles.preprocess = 0.0
	particles.randomness = lerpf(0.18, 0.38, strength)
	particles.lifetime_randomness = 0.24
	particles.local_coords = false
	particles.spread = lerpf(7.0, 20.0, strength)
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = DisplaySettings.scale_value(12.0 + 12.0 * strength)
	particles.initial_velocity_max = DisplaySettings.scale_value(30.0 + 44.0 * strength)
	particles.damping_min = DisplaySettings.scale_value(120.0)
	particles.damping_max = DisplaySettings.scale_value(250.0)
	particles.scale_amount_min = DisplaySettings.scale_factor() * lerpf(0.45, 0.85, strength)
	particles.scale_amount_max = DisplaySettings.scale_factor() * lerpf(0.90, 1.45, strength)
	particles.color = Color(color.r, color.g, color.b, lerpf(0.34, 0.68, strength))
	_sync_weapon_level_particles()

func _remove_weapon_level_effect() -> void:
	_remove_legacy_weapon_level_effect()
	var particles := get_node_or_null("BulletLevelParticles") as CPUParticles2D
	if particles:
		particles.queue_free()

func _remove_legacy_weapon_level_effect() -> void:
	var light := get_node_or_null("BulletLevelLight") as PointLight2D
	if light:
		light.queue_free()
	var glow := get_node_or_null("BulletLevelGlow") as Sprite2D
	if glow:
		glow.queue_free()

func _sync_weapon_level_particles() -> void:
	var particles := get_node_or_null("BulletLevelParticles") as CPUParticles2D
	if particles == null:
		return
	particles.global_rotation = 0.0
	if velocity.length_squared() > 1.0:
		var trail_direction := -velocity.normalized()
		particles.direction = trail_direction
		particles.global_position = global_position + trail_direction * DisplaySettings.scale_value(8.0)
	else:
		particles.direction = Vector2.DOWN
		particles.global_position = global_position

func _make_level_light_texture() -> Texture2D:
	if _level_light_texture:
		return _level_light_texture
	var size := 7
	var center := Vector2(size * 0.5 - 0.5, size * 0.5 - 0.5)
	var radius := float(size) * 0.5
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var alpha := clampf(1.0 - distance / radius, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_level_light_texture = ImageTexture.create_from_image(image)
	return _level_light_texture

func _ensure_missile_trail() -> void:
	if get_node_or_null("MissileTrail"):
		return
	var trail := CPUParticles2D.new()
	trail.name = "MissileTrail"
	trail.position = Vector2(0, 26)
	trail.emitting = true
	trail.amount = 14
	trail.lifetime = 0.18
	trail.preprocess = 0.18
	trail.local_coords = true
	trail.direction = Vector2(0, 1)
	trail.spread = 14.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 35.0
	trail.initial_velocity_max = 60.0
	trail.damping_min = 120.0
	trail.damping_max = 190.0
	trail.scale_amount_min = 0.8
	trail.scale_amount_max = 1.6
	trail.color = Color(1.0, 0.48, 0.14, 0.58)
	add_child(trail)

func _spawn_missile_burst() -> void:
	var burst := CPUParticles2D.new()
	burst.amount = 18
	burst.lifetime = 0.28
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.initial_velocity_min = 75.0
	burst.initial_velocity_max = 190.0
	burst.scale_amount_min = 1.2
	burst.scale_amount_max = 2.8
	burst.color = Color(1.0, 0.46, 0.12, 0.78)
	_spawn_parent().add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	burst.finished.connect(burst.queue_free)

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root

func _spawn_hit_spark(pos: Vector2) -> void:
	if hit_spark_timer > 0.0:
		return
	hit_spark_timer = 0.1
	var spark := BulletHitSparkScene.instantiate() as Node2D
	_spawn_parent().add_child(spark)
	spark.global_position = pos
	if bullet_type == "BulletLaser":
		spark.scale = Vector2.ONE * 1.35
