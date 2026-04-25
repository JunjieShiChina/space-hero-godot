extends Area2D
class_name SpaceBullet

var bullet_type := "Bullet1"
var shooter_team := "player"
var velocity := Vector2.ZERO
var damage := 10.0
var life_time := 4.0
var pierce := false
var homing := false
var homing_range := 0.0
var homing_direct := false
var damage_tick_interval := 0.0
var damage_tick_timer := 0.0
var spin := 0.0
var spin_angle := 0.0
var retired := false
var hit_spark_timer := 0.0

const BulletHitSparkScene := preload("res://scenes/components/bullet_hit_spark.tscn")

func setup(type_name: String, team: String, pos: Vector2, direction: Vector2, overrides := {}) -> void:
	bullet_type = type_name
	shooter_team = team
	global_position = pos
	rotation = direction.angle() + PI / 2.0
	var info := bullet_info(type_name)
	for key in overrides.keys():
		info[key] = overrides[key]
	damage = float(info.damage)
	velocity = direction.normalized() * DisplaySettings.scale_value(float(info.speed))
	life_time = float(info.life)
	pierce = bool(info.pierce)
	homing = bool(info.homing)
	homing_range = DisplaySettings.scale_value(float(info.get("homing_range", 0.0)))
	homing_direct = bool(info.get("homing_direct", false))
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
		"BulletArrow": {"speed": 1080.0, "damage": 3.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/WyvernHornBow.png", "scale": 0.30, "radius": 16.0, "height": 48.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "arrow"},
		"BulletMissile": {"speed": 540.0, "damage": 50.0, "interval": 1.5, "life": 5.0, "texture": "res://assets/sprites/spr_missile.png", "scale": 0.70, "radius": 10.0, "height": 42.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "missile"},
		"BulletLaser": {"speed": 0.0, "damage": 1.0, "interval": 2.0, "life": 1.5, "tick_interval": 0.08, "texture": "res://assets/sprites/bosslaser.png", "scale": 1.0, "radius": 18.0, "height": 810.0, "pierce": true, "homing": false, "spin": 0.0, "sfx": "laser"},
		"BulletFire": {"speed": 540.0, "damage": 10.0, "interval": 1.0, "life": 3.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.72, "radius": 12.0, "height": 34.0, "pierce": false, "homing": false, "spin": 5.0, "sfx": "bullet_fire"},
		"BulletYue": {"speed": 540.0, "damage": 6.0, "interval": 0.2, "life": 3.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(576, 16, 16, 17), Rect2(592, 16, 16, 17), Rect2(608, 16, 16, 17), Rect2(624, 16, 16, 17)], "scale": 1.35, "radius": 8.0, "height": 24.0, "pierce": false, "homing": false, "spin": 8.0, "sfx": "bullet_yue"},
		"Bullet3": {"speed": 1080.0, "damage": 5.0, "interval": 0.18, "life": 3.0, "texture": "res://assets/sprites/bullet6.png", "scale": 0.50, "radius": 8.0, "height": 34.0, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"FollowBullet": {"speed": 1080.0, "damage": 2.0, "interval": 0.1, "life": 4.0, "texture": "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png", "frames": [Rect2(96, 48, 16, 16), Rect2(112, 48, 16, 16), Rect2(128, 48, 16, 16), Rect2(144, 48, 16, 16)], "scale": 1.2, "radius": 8.0, "height": 22.0, "pierce": false, "homing": true, "homing_range": 576.0, "homing_direct": true, "spin": 0.0, "sfx": "shoot"},
	}
	return map.get(type_name, map["Bullet1"])

func _physics_process(delta: float) -> void:
	life_time -= delta
	hit_spark_timer = maxf(0.0, hit_spark_timer - delta)
	if life_time <= 0:
		call_deferred("_retire")
		return
	if homing:
		var target := _find_target()
		if target:
			var desired := (target.global_position - global_position).normalized() * velocity.length()
			velocity = desired if homing_direct else velocity.lerp(desired, 4.0 * delta)
	if velocity != Vector2.ZERO:
		global_position += velocity * delta
		if spin != 0.0:
			spin_angle += spin * delta
		rotation = velocity.angle() + PI / 2.0 + spin_angle
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

func _find_target() -> CombatBody:
	var best: CombatBody = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is CombatBody:
			var dist := global_position.distance_squared_to(node.global_position)
			if homing_range > 0.0 and dist > homing_range * homing_range:
				continue
			if dist < best_dist:
				best = node
				best_dist = dist
	return best

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
