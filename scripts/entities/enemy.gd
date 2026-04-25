extends CombatBody
class_name EnemyShip

var velocity := Vector2.ZERO
var ai := "drift"
var shoot_timer := 1.3
var shoot_interval := 1.4
var bullet_type := "Bullet1"
var player: PlayerShip
var can_shoot := true
var small_laser_timer := 1.0
var small_laser_count := 0
var small_laser_pause_timer := 0.0
var small_laser_paused := false
var rotation_ready := false
var rotation_target_y := 0.0

const UNITY_UNIT := 108.0
const METEOR_VISUAL_TARGET := 82.0
const EnemyFireTailScene := preload("res://scenes/components/enemy_fire_tail.tscn")

func configure(kind: String, pos: Vector2, target: PlayerShip) -> void:
	player = target
	var config := {
		"ship": ["res://assets/sprites/Spaceship_Enemy - SingleShot.png", 5.0, 25.0, "ship", Vector2(randf_range(-UNITY_UNIT * 3.0, UNITY_UNIT * 3.0), randf_range(UNITY_UNIT, UNITY_UNIT * 3.0)), "drift", "Bullet2", 2.0, "coin1"],
		"ep2": ["res://assets/sprites/Spaceship_Enemy - DualShot.png", 10.0, 26.0, "ep2", Vector2(randf_range(-UNITY_UNIT * 3.0, UNITY_UNIT * 3.0), randf_range(UNITY_UNIT, UNITY_UNIT * 3.0)), "chase", "Bullet2", 2.0, "coin2"],
		"rotation_ep": ["res://assets/sprites/Spaceship_Enemy - QuadShot.png", 50.0, 30.0, "rotation_ep", Vector2(0, UNITY_UNIT), "rotate", "BulletYue", 0.2, "coin3"],
		"meteor_enemy": ["res://assets/sprites/Spaceship_Enemy - ArcShot.png", 20.0, 28.0, "meteor_enemy", Vector2(0, randf_range(UNITY_UNIT * 5.0, UNITY_UNIT * 10.0)), "meteor_enemy", "Bullet1", 0.0, "coin3"],
		"meteor": ["res://assets/sprites/meteor0001.png", 30.0, 30.0, "meteor", Vector2(0, randf_range(324, 864)), "meteor", "Bullet1", 0.0, ""],
		"small_boss": ["res://assets/sprites/Spaceship_Enemy - QuadShot.png", 500.0, 40.0, "small_boss", Vector2(0, 105), "small_boss", "Bullet2", 1.0, "coin3"],
	}
	var c: Array = config[kind]
	global_position = pos
	setup(c[0], c[2], "enemy", c[1])
	stat_key = c[3]
	velocity = DisplaySettings.to_current(c[4])
	ai = c[5]
	bullet_type = c[6]
	shoot_interval = c[7] if c.size() > 7 else 1.4
	coin_type = str(c[8]) if c.size() > 8 else "coin1"
	can_shoot = shoot_interval > 0.0
	if ai == "rotate":
		can_shoot = false
		rotation_ready = false
		rotation_target_y = DisplaySettings.scale_value(324.0)
	if ai == "meteor_enemy":
		can_shoot = false
		_attach_enemy_fire_tail()
		AudioBus.play_sfx("meteor", -12.0)
	if ai == "meteor":
		can_shoot = false
		coin_drop_chance = 0.0
		hp_drop_chance = 0.0
		_apply_meteor_visual_scale()
		AudioBus.play_sfx("meteor", -12.0)
	shoot_timer = shoot_interval if ai == "small_boss" else 0.5
	rotation = 0.0 if ai in ["rotate", "small_boss", "meteor"] else PI
	add_to_group("enemy")

func _process(delta: float) -> void:
	match ai:
		"chase":
			if player and not player.dead and global_position.distance_to(player.global_position) < DisplaySettings.scale_value(540):
				velocity = (player.global_position - global_position).normalized() * DisplaySettings.scale_value(UNITY_UNIT * 5.0)
				rotation = velocity.angle() + PI / 2.0
		"rotate":
			_process_rotation_ep(delta)
		"small_boss":
			velocity.x = DisplaySettings.scale_value(sin(Time.get_ticks_msec() * 0.002) * 210)
			velocity.y = DisplaySettings.scale_value(60)
	global_position += velocity * delta
	if can_shoot:
		if ai == "small_boss":
			_process_small_boss_fire(delta)
		else:
			shoot_timer -= delta
			if shoot_timer <= 0:
				shoot_timer = shoot_interval
				_shoot()
	if global_position.y > DisplaySettings.scale_value(1230) or global_position.x < DisplaySettings.scale_value(-180) or global_position.x > DisplaySettings.scale_value(2100):
		_retire()

func _process_rotation_ep(delta: float) -> void:
	if not rotation_ready:
		velocity = Vector2(0, DisplaySettings.scale_value(UNITY_UNIT))
		if global_position.y + velocity.y * delta >= rotation_target_y:
			global_position.y = rotation_target_y
			velocity = Vector2.ZERO
			rotation_ready = true
			can_shoot = true
			shoot_timer = 0.5
		return
	rotation += delta * deg_to_rad(300.0)
	velocity = Vector2.ZERO

func _shoot() -> void:
	var muzzle_distance := UNITY_UNIT if bullet_type == "Bullet2" else UNITY_UNIT * 0.5
	_play_bullet_sfx(bullet_type)
	_spawn_bullet(bullet_type, global_position + _forward() * DisplaySettings.scale_value(muzzle_distance), _forward())

func _process_small_boss_fire(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval
		if randi_range(0, 1) == 0:
			_shoot_small_boss_ring()

	if small_laser_paused:
		small_laser_pause_timer -= delta
		if small_laser_pause_timer <= 0.0:
			small_laser_paused = false
			small_laser_count = 0
			small_laser_timer = 1.0
		return

	small_laser_timer -= delta
	if small_laser_timer <= 0.0:
		small_laser_timer = 1.0
		_shoot_small_boss_laser()
		small_laser_count += 1
		if small_laser_count >= 2:
			small_laser_paused = true
			small_laser_pause_timer = 4.0

func _shoot_small_boss_ring() -> void:
	_play_bullet_sfx("Bullet2")
	var angle := -60.0
	for i in 18:
		angle += 20.0
		_spawn_bullet("Bullet2", global_position, Vector2.DOWN.rotated(deg_to_rad(angle)))

func _shoot_small_boss_laser() -> void:
	if player == null or player.dead:
		return
	_play_bullet_sfx("BulletLaser")
	var direction := (player.global_position - global_position).normalized()
	_spawn_bullet("BulletLaser", global_position + direction * DisplaySettings.scale_value(90.0), direction, {"life": 3.0})

func _spawn_bullet(type_name: String, origin: Vector2, direction: Vector2, overrides := {}) -> SpaceBullet:
	var bullet := SpaceBullet.new()
	_spawn_parent().add_child(bullet)
	bullet.setup(type_name, "enemy", origin, direction, overrides)
	return bullet

func _forward() -> Vector2:
	return Vector2.UP.rotated(rotation).normalized()

func _play_bullet_sfx(type_name: String) -> void:
	var sfx_key: String = SpaceBullet.bullet_info(type_name).sfx
	AudioBus.play_sfx(sfx_key, -14.0)

func _attach_enemy_fire_tail() -> void:
	if sprite == null or sprite.get_node_or_null("FireTail") != null:
		return
	var fire_tail := EnemyFireTailScene.instantiate() as Node2D
	fire_tail.name = "FireTail"
	fire_tail.position = Vector2(0, 22)
	fire_tail.rotation = PI
	fire_tail.scale = Vector2.ONE * 1.05
	sprite.add_child(fire_tail)

func _apply_meteor_visual_scale() -> void:
	if sprite == null or sprite.texture == null:
		return
	var texture_size: Vector2 = sprite.texture.get_size()
	var max_size := maxf(texture_size.x, texture_size.y)
	if max_size <= 0.0:
		return
	sprite.scale = Vector2.ONE * (DisplaySettings.scale_value(METEOR_VISUAL_TARGET) / max_size)

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
