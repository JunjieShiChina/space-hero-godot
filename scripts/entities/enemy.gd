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
var phase_time := 0.0
var phase_dash_timer := 1.1
var phase_dash_time_left := 0.0
var phase_dash_direction := 1.0
var phase_burst_side := 1.0

@export var enemy_kind := "ship"
@export var enemy_health := 5.0
@export var collision_radius := 25.0
@export var statistic_key := "ship"
@export var base_velocity_design := Vector2.ZERO
@export var random_velocity_x_design := Vector2.ZERO
@export var random_velocity_y_design := Vector2.ZERO
@export var ai_mode := "drift"
@export var starting_bullet_type := "Bullet2"
@export var starting_shoot_interval := 2.0
@export var starting_coin_type := "coin1"

const UNITY_UNIT := 108.0
const METEOR_VISUAL_TARGET := 82.0
const EnemyFireTailScene := preload("res://scenes/components/enemy_fire_tail.tscn")

func configure(_kind: String, pos: Vector2, target: PlayerShip) -> void:
	player = target
	global_position = pos
	setup(_scene_texture_path(), collision_radius, "enemy", enemy_health)
	stat_key = statistic_key
	velocity = DisplaySettings.to_current(_roll_initial_velocity())
	ai = ai_mode
	bullet_type = starting_bullet_type
	shoot_interval = starting_shoot_interval
	coin_type = starting_coin_type
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
	if ai == "phase_interceptor":
		can_shoot = true
		phase_time = randf_range(0.0, TAU)
		phase_dash_timer = randf_range(0.55, 1.25)
		phase_dash_time_left = 0.0
		phase_dash_direction = -1.0 if global_position.x > DisplaySettings.logical_center().x else 1.0
		phase_burst_side = 1.0
	shoot_timer = shoot_interval if ai == "small_boss" else 0.5
	rotation = 0.0 if ai in ["rotate", "small_boss", "meteor", "phase_interceptor"] else PI
	add_to_group("enemy")

func _scene_texture_path() -> String:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite and sprite.texture:
		return sprite.texture.resource_path
	return ""

func _roll_initial_velocity() -> Vector2:
	var result := base_velocity_design
	if not is_equal_approx(random_velocity_x_design.x, random_velocity_x_design.y):
		result.x += randf_range(random_velocity_x_design.x, random_velocity_x_design.y)
	if not is_equal_approx(random_velocity_y_design.x, random_velocity_y_design.y):
		result.y += randf_range(random_velocity_y_design.x, random_velocity_y_design.y)
	return result

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
		"phase_interceptor":
			_process_phase_interceptor(delta)
	global_position += velocity * delta
	if can_shoot:
		if ai == "phase_interceptor":
			_process_phase_fire(delta)
		elif ai == "small_boss":
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

func _process_phase_interceptor(delta: float) -> void:
	phase_time += delta
	var drift_x := sin(phase_time * 2.35) * 255.0
	var fall_y := 166.0 + sin(phase_time * 0.85) * 42.0
	phase_dash_timer -= delta
	if phase_dash_time_left > 0.0:
		phase_dash_time_left -= delta
		drift_x += phase_dash_direction * 720.0
		if sprite:
			sprite.modulate = Color(1.22, 1.4, 1.55, 1.0)
	else:
		if sprite:
			sprite.modulate = sprite.modulate.lerp(Color.WHITE, 8.0 * delta)
		if phase_dash_timer <= 0.0:
			phase_dash_timer = randf_range(1.55, 2.25)
			phase_dash_time_left = 0.18
			if global_position.x < DisplaySettings.scale_value(420.0):
				phase_dash_direction = 1.0
			elif global_position.x > DisplaySettings.scale_value(1500.0):
				phase_dash_direction = -1.0
			else:
				phase_dash_direction *= -1.0
	velocity = DisplaySettings.to_current(Vector2(drift_x, fall_y))
	rotation = clampf(velocity.x / DisplaySettings.scale_value(1600.0), -0.22, 0.22)

func _process_phase_fire(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer > 0.0:
		return
	shoot_timer = shoot_interval
	_shoot_phase_spread()

func _shoot_phase_spread() -> void:
	var base_direction := Vector2.DOWN
	if player and not player.dead:
		var to_player := player.global_position - global_position
		if to_player.length_squared() > 1.0 and to_player.y > 0.0:
			base_direction = to_player.normalized()
	_play_bullet_sfx("BulletPhaseShard")
	var origin := global_position + base_direction * DisplaySettings.scale_value(54.0)
	phase_burst_side *= -1.0
	for angle in [-0.44, -0.22, 0.0, 0.22, 0.44]:
		var curve := 0.0 if is_zero_approx(angle) else 0.68 + absf(angle) * 0.55
		var curve_direction := phase_burst_side
		if angle < 0.0:
			curve_direction *= -1.0
		_spawn_bullet("BulletPhaseShard", origin, base_direction.rotated(angle), {
			"curve_rate": curve,
			"curve_direction": curve_direction,
		})

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
	var bullet := SpaceBullet.create(type_name)
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
