extends CombatBody
class_name BossShip

var boss_id := 1
var player: PlayerShip
var stage: Node
var primary_timer := 1.0
var target := Vector2.ZERO
var boss1_special_wait := 3.0
var boss1_special_timer := 0.0
var boss1_special_index := 0
var boss1_special_active := false
var boss1_moving_right := true
var boss2_needs_target := true
var boss2_laser_timer := 1.0
var boss2_laser_count := 0
var boss2_laser_pause_timer := 0.0
var boss2_laser_paused := false
var boss3_attack_type := 0
var boss3_choice_timer := 1.0
var boss3_attack_timer := 1.0
var boss3_follow_timer := 1.0

const UNITY_UNIT := 108.0
const BossDeathEffectScene := preload("res://scenes/components/boss_death_effect.tscn")

func configure(id: int, target_player: PlayerShip, owner_stage: Node) -> void:
	boss_id = id
	player = target_player
	stage = owner_stage
	var texture := "res://assets/sprites/boss1.png"
	var hp := 2000.0
	scale = Vector2.ONE
	if id == 2:
		texture = "res://assets/sprites/Spaceship_Boss 1.png"
		hp = 1200.0
	elif id == 3:
		texture = "res://assets/sprites/Spaceship_Boss 3.png"
		hp = 1500.0
	global_position = DisplaySettings.to_current(Vector2(960, -195))
	setup(texture, 84, "enemy", hp)
	if id == 1:
		scale = Vector2.ONE * 2.25
	stat_key = "boss%d" % id
	add_to_group("enemy")
	died.connect(_on_boss_died)
	target = DisplaySettings.to_current(Vector2(960, 202.5))
	_reset_attack_state()

func _process(delta: float) -> void:
	if dead:
		return
	_move(delta)
	match boss_id:
		1:
			_process_boss1(delta)
		2:
			_process_boss2(delta)
		3:
			_process_boss3(delta)
	if stage and stage.has_method("update_boss_health"):
		stage.update_boss_health(health / max_health)

func _move(delta: float) -> void:
	match boss_id:
		1:
			_update_boss1_target()
		2:
			if boss2_needs_target:
				_choose_boss2_target()
		3:
			pass
	var speed := DisplaySettings.scale_value(225.0)
	if boss_id == 1:
		speed = DisplaySettings.scale_value(UNITY_UNIT * 1.25)
	if boss_id == 2:
		speed = DisplaySettings.scale_value(UNITY_UNIT * 3.0)
	elif boss_id == 3:
		speed = DisplaySettings.scale_value(UNITY_UNIT * 2.0)
	global_position = global_position.move_toward(target, delta * speed)

func _reset_attack_state() -> void:
	primary_timer = 1.0
	boss1_special_wait = 3.0
	boss1_special_timer = 0.0
	boss1_special_index = 0
	boss1_special_active = false
	boss1_moving_right = true
	boss2_needs_target = boss_id == 2
	boss2_laser_timer = 1.0
	boss2_laser_count = 0
	boss2_laser_pause_timer = 0.0
	boss2_laser_paused = false
	boss3_attack_type = 0
	boss3_choice_timer = 1.0
	boss3_attack_timer = 1.0
	boss3_follow_timer = 1.0

func _process_boss1(delta: float) -> void:
	primary_timer -= delta
	if primary_timer <= 0.0:
		primary_timer = 2.0
		_shoot_boss1_primary()

	if boss1_special_active:
		boss1_special_timer -= delta
		if boss1_special_timer <= 0.0:
			_shoot_boss1_special_step()
			boss1_special_index += 1
			if boss1_special_index >= 10:
				boss1_special_active = false
				boss1_special_wait = 3.0
			else:
				boss1_special_timer = 0.2
	else:
		boss1_special_wait -= delta
		if boss1_special_wait <= 0.0:
			boss1_special_active = true
			boss1_special_index = 0
			boss1_special_timer = 0.0

func _process_boss2(delta: float) -> void:
	primary_timer -= delta
	if primary_timer <= 0.0:
		primary_timer = 0.5
		if randi_range(0, 1) == 0:
			_shoot_boss2_ring()

	if boss2_laser_paused:
		boss2_laser_pause_timer -= delta
		if boss2_laser_pause_timer <= 0.0:
			boss2_laser_paused = false
			boss2_laser_count = 0
			boss2_laser_timer = 1.0
			boss2_needs_target = true
		return

	if global_position.distance_to(target) > DisplaySettings.scale_value(18.0):
		return

	boss2_laser_timer -= delta
	if boss2_laser_timer <= 0.0:
		boss2_laser_timer = 1.0
		_shoot_boss2_laser()
		boss2_laser_count += 1
		if boss2_laser_count >= 4:
			boss2_laser_paused = true
			boss2_laser_pause_timer = 4.0

func _process_boss3(delta: float) -> void:
	boss3_choice_timer -= delta
	if boss3_choice_timer <= 0.0:
		boss3_choice_timer = 4.0
		boss3_attack_type = randi_range(0, 2)

	boss3_follow_timer -= delta
	if boss3_follow_timer <= 0.0:
		boss3_follow_timer = 4.0
		if player:
			target = Vector2(clamp(player.global_position.x, DisplaySettings.scale_value(240), DisplaySettings.scale_value(1680)), DisplaySettings.scale_value(195))

	boss3_attack_timer -= delta
	if boss3_attack_timer <= 0.0:
		boss3_attack_timer = 1.0
		match boss3_attack_type:
			0:
				_shoot_boss3_scatter()
			1:
				_shoot_boss3_missiles()
			2:
				_shoot_boss3_lasers()

func _shoot_boss1_primary() -> void:
	_play_bullet_sfx("Bullet2")
	var angle := -60.0
	for i in 10:
		angle += 10.0
		_spawn_bullet("Bullet2", global_position + DisplaySettings.to_current(Vector2(0, UNITY_UNIT * 0.5)), Vector2.DOWN.rotated(deg_to_rad(angle)))

func _shoot_boss1_special_step() -> void:
	_play_bullet_sfx("BulletFire")
	var angle := -50.0 + float(boss1_special_index) * 10.0
	_spawn_bullet("BulletFire", global_position + DisplaySettings.to_current(Vector2(0, UNITY_UNIT * 0.5)), Vector2.DOWN.rotated(deg_to_rad(angle)))

func _update_boss1_target() -> void:
	var target_y := DisplaySettings.scale_value(217.5)
	if global_position.y < target_y - DisplaySettings.scale_value(8.0):
		target = Vector2(global_position.x, target_y)
		return
	var half_width := _boss1_half_width()
	var left_x := half_width
	var right_x := DisplaySettings.logical_size().x - half_width
	if boss1_moving_right:
		target = Vector2(right_x, target_y)
		if global_position.x >= right_x - DisplaySettings.scale_value(8.0):
			boss1_moving_right = false
	else:
		target = Vector2(left_x, target_y)
		if global_position.x <= left_x + DisplaySettings.scale_value(8.0):
			boss1_moving_right = true

func _shoot_boss2_ring() -> void:
	_play_bullet_sfx("Bullet2")
	var angle := -60.0
	for i in 18:
		angle += 20.0
		_spawn_bullet("Bullet2", global_position, Vector2.DOWN.rotated(deg_to_rad(angle)))

func _shoot_boss2_laser() -> void:
	if player == null or player.dead:
		return
	_play_bullet_sfx("BulletLaser")
	var direction := (player.global_position - global_position).normalized()
	_spawn_bullet("BulletLaser", global_position + direction * DisplaySettings.scale_value(UNITY_UNIT * 1.5), direction, {"life": 3.0})

func _shoot_boss3_scatter() -> void:
	_play_bullet_sfx("Bullet2")
	for origin in [Vector2(-UNITY_UNIT * 0.6, UNITY_UNIT * 1.22), Vector2(UNITY_UNIT * 0.6, UNITY_UNIT * 1.22)]:
		var angle := -50.0
		for i in 8:
			angle += 10.0
			_spawn_bullet("Bullet2", global_position + DisplaySettings.to_current(origin), Vector2.DOWN.rotated(deg_to_rad(angle)))

func _shoot_boss3_missiles() -> void:
	_play_bullet_sfx("BulletMissile")
	for origin in [Vector2(-UNITY_UNIT * 0.6, UNITY_UNIT * 1.3), Vector2(UNITY_UNIT * 0.6, UNITY_UNIT * 1.3)]:
		_spawn_bullet("BulletMissile", global_position + DisplaySettings.to_current(origin), Vector2.DOWN)

func _shoot_boss3_lasers() -> void:
	_play_bullet_sfx("BulletLaser")
	for origin in [Vector2(-UNITY_UNIT * 0.6, UNITY_UNIT * 0.8), Vector2(UNITY_UNIT * 0.6, UNITY_UNIT * 0.8)]:
		_spawn_bullet("BulletLaser", global_position + DisplaySettings.to_current(origin), Vector2.DOWN, {"life": 1.0})

func _choose_boss2_target() -> void:
	boss2_needs_target = false
	target = Vector2(
		randf_range(DisplaySettings.scale_value(240), DisplaySettings.scale_value(1680)),
		randf_range(DisplaySettings.scale_value(142.5), DisplaySettings.scale_value(390))
	)

func _spawn_bullet(type_name: String, origin: Vector2, direction: Vector2, overrides := {}) -> SpaceBullet:
	var bullet := SpaceBullet.create(type_name)
	_spawn_parent().add_child(bullet)
	bullet.setup(type_name, "enemy", origin, direction, overrides)
	return bullet

func _play_bullet_sfx(type_name: String) -> void:
	var sfx_key: String = SpaceBullet.bullet_info(type_name).sfx
	AudioBus.play_sfx(sfx_key, -14.0)

func _spawn_burst() -> void:
	var effect := BossDeathEffectScene.instantiate() as Node2D
	_spawn_parent().add_child(effect)
	effect.global_position = global_position
	effect.scale = Vector2.ONE * DisplaySettings.scale_factor()

func _on_boss_died(_body: CombatBody) -> void:
	if stage and stage.has_method("spawn_boss_rewards"):
		stage.spawn_boss_rewards(global_position)
	if stage and stage.has_method("on_boss_defeated"):
		stage.on_boss_defeated()

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root

func _boss1_half_width() -> float:
	if sprite and sprite.texture:
		var sprite_width := sprite.texture.get_size().x * sprite.scale.x * scale.x
		return max(DisplaySettings.scale_value(96.0), sprite_width * 0.5)
	return DisplaySettings.scale_value(168.0)
