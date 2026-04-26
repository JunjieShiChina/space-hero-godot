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
var retired := false
var hit_spark_timer := 0.0
var _template_node_states: Dictionary = {}
var _template_shape_states: Dictionary = {}

const BulletHitSparkScene := preload("res://scenes/components/bullet_hit_spark.tscn")
const BULLET_SCENE_PATHS := {
	"Bullet1": "res://scenes/entities/bullets/bullet_1.tscn",
	"Bullet2": "res://scenes/entities/bullets/bullet_2.tscn",
	"BulletArrow": "res://scenes/entities/bullets/bullet_arrow.tscn",
	"BulletMissile": "res://scenes/entities/bullets/bullet_missile.tscn",
	"BulletLaser": "res://scenes/entities/bullets/bullet_laser.tscn",
	"BulletFire": "res://scenes/entities/bullets/bullet_fire.tscn",
	"BulletYue": "res://scenes/entities/bullets/bullet_yue.tscn",
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
	rotation = _rotation_for_direction(safe_direction)
	var info := bullet_info(type_name)
	for key in overrides.keys():
		info[key] = overrides[key]
	damage = float(info.damage)
	base_speed = DisplaySettings.scale_value(float(info.speed))
	velocity = safe_direction * base_speed
	life_time = float(info.life)
	pierce = bool(info.pierce)
	homing = bool(info.homing)
	homing_range = DisplaySettings.scale_value(float(info.get("homing_range", 0.0)))
	homing_direct = bool(info.get("homing_direct", false))
	homing_delay_timer = float(info.get("homing_delay", 0.0))
	visual_angle_offset = float(info.get("visual_angle_offset", PI / 2.0))
	damage_tick_interval = float(info.get("tick_interval", 0.0))
	damage_tick_timer = damage_tick_interval
	spin = float(info.spin)
	spin_angle = 0.0
	collision_layer = 4 if team == "player" else 8
	collision_mask = 2 | 32 if team == "player" else 1 | 32
	_make_visual(info)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

static func bullet_info(type_name: String) -> Dictionary:
	var map := {
		"Bullet1": {"speed": 1080.0, "damage": 5.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.58, "radius": 7.0, "height": 30.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"Bullet2": {"speed": 540.0, "damage": 5.0, "interval": 2.0, "life": 4.0, "texture": "res://assets/sprites/bullet4.png", "scale": 0.58, "radius": 10.0, "height": 32.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot2"},
		"BulletArrow": {"speed": 1080.0, "damage": 3.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/WyvernHornBow.png", "scale": 0.30, "radius": 16.0, "height": 48.0, "pierce": false, "homing": false, "spin": 0.0, "visual_angle_offset": PI / 4.0, "sfx": "arrow"},
		"BulletMissile": {"speed": 540.0, "damage": 50.0, "interval": 1.5, "life": 5.0, "texture": "res://assets/sprites/spr_missile.png", "scale": 0.70, "radius": 10.0, "height": 42.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "missile"},
		"BulletLaser": {"speed": 0.0, "damage": 1.0, "interval": 2.0, "life": 1.5, "tick_interval": 0.08, "texture": "res://assets/sprites/bosslaser.png", "scale": 1.0, "radius": 18.0, "height": 810.0, "pierce": true, "homing": false, "spin": 0.0, "sfx": "laser"},
		"BulletFire": {"speed": 540.0, "damage": 10.0, "interval": 1.0, "life": 3.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.72, "radius": 12.0, "height": 34.0, "pierce": false, "homing": false, "spin": 5.0, "sfx": "bullet_fire"},
		"BulletYue": {"speed": 540.0, "damage": 6.0, "interval": 0.2, "life": 3.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(576, 16, 16, 17), Rect2(592, 16, 16, 17), Rect2(608, 16, 16, 17), Rect2(624, 16, 16, 17)], "scale": 1.35, "radius": 8.0, "height": 24.0, "pierce": false, "homing": false, "spin": 8.0, "sfx": "bullet_yue"},
		"Bullet3": {"speed": 1080.0, "damage": 5.0, "interval": 0.18, "life": 3.0, "texture": "res://assets/sprites/bullet6.png", "scale": 0.50, "radius": 8.0, "height": 34.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"FollowBullet": {"speed": 1080.0, "damage": 2.0, "interval": 0.1, "life": 4.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(96, 48, 16, 16), Rect2(112, 48, 16, 16), Rect2(128, 48, 16, 16), Rect2(144, 48, 16, 16)], "scale": 1.2, "radius": 8.0, "height": 22.0, "pierce": false, "homing": true, "homing_range": 576.0, "homing_direct": true, "homing_delay": 0.14, "visual_angle_offset": -PI / 4.0, "spin": 0.0, "sfx": "shoot"},
	}
	return map.get(type_name, map["Bullet1"])

func _physics_process(delta: float) -> void:
	life_time -= delta
	hit_spark_timer = maxf(0.0, hit_spark_timer - delta)
	if life_time <= 0:
		call_deferred("_retire")
		return
	if homing:
		if homing_delay_timer > 0.0:
			homing_delay_timer -= delta
		else:
			var target := _find_target()
			if target:
				var target_delta := target.global_position - global_position
				if target_delta.length_squared() > 1.0:
					var current_speed := velocity.length()
					if current_speed <= 0.0:
						current_speed = base_speed
					var desired := target_delta.normalized() * current_speed
					velocity = desired if homing_direct else velocity.lerp(desired, 4.0 * delta)
	if velocity.is_zero_approx() and base_speed > 0.0:
		velocity = Vector2.UP * base_speed
	if velocity != Vector2.ZERO:
		global_position += velocity * delta
		if spin != 0.0:
			spin_angle += spin * delta
		rotation = _rotation_for_direction(velocity)
	elif spin != 0.0:
		rotation += spin * delta
	if damage_tick_interval > 0.0:
		damage_tick_timer -= delta
		if damage_tick_timer <= 0.0:
			damage_tick_timer = damage_tick_interval
			_damage_overlapping_targets()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("reflect_bullet"):
		area.reflect_bullet(self)
		return
	if area is CombatBody and area.team != shooter_team:
		var body := area as CombatBody
		if body.dead:
			return
		_spawn_hit_spark(global_position)
		body.take_damage(damage)
		if not pierce:
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
	if bullet_type == "BulletMissile":
		_spawn_missile_burst()
	visible = false
	set_process(false)
	set_physics_process(false)
	call_deferred("queue_free")

func _make_visual(info: Dictionary) -> void:
	if use_scene_template:
		_apply_scene_template()
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

func _apply_scene_template() -> void:
	for node_name in ["Sprite2D", "AnimatedSprite2D", "MissileTrail"]:
		var visual_node := get_node_or_null(node_name) as Node2D
		if visual_node:
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
			var dist := global_position.distance_squared_to(body.global_position)
			if dist <= DisplaySettings.scale_value(12.0) * DisplaySettings.scale_value(12.0):
				continue
			if homing_range > 0.0 and dist > homing_range * homing_range:
				continue
			if dist < best_dist:
				best = body
				best_dist = dist
	return best

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
			body.take_damage(damage)

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
