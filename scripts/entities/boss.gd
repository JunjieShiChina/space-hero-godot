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
var boss2_laser_warning: BossLaserWarning = null
var boss3_attack_type := 0
var boss3_choice_timer := 1.0
var boss3_attack_timer := 1.0
var boss3_follow_timer := 1.0

const UNITY_UNIT := 108.0
const BossDeathEffectScene := preload("res://scenes/components/boss_death_effect.tscn")
const BossLaserWarningScene := preload("res://scenes/components/boss_laser_warning.tscn")

func configure(id: int, target_player: PlayerShip, owner_stage: Node) -> void:
	boss_id = id
	player = target_player
	stage = owner_stage
	var texture := "res://assets/sprites/boss1.png"
	var hp := 2000.0
	scale = Vector2.ONE
	if id == 2:
		texture = "res://assets/sprites/Spaceship_Boss 3.png"
		hp = 2000.0
	elif id == 3:
		texture = "res://assets/sprites/Spaceship_Boss 1.png"
		hp = 1500.0
		scale = Vector2.ONE * 1.5
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
			if _boss2_laser_sequence_active():
				return
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

func _shoot_boss2_laser():
	if player == null or player.dead:
		return
	var direction := (player.global_position - global_position).normalized()
	var warning := _spawn_boss_laser_warning(
		_laser_muzzle_origin(direction, 1.0),
		direction,
		{
			"life": 3.0,
			"start_distance": 2.0,
		}
	)
	boss2_laser_warning = warning
	return warning

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

func _shoot_boss3_lasers():
	var warnings: Array[BossLaserWarning] = []
	for origin in _boss3_laser_mount_offsets():
		var warning := _spawn_boss_laser_warning(
			to_global(origin),
			Vector2.DOWN,
			{
				"life": 1.0,
				"cast_time": 0.12,
				"start_distance": 34.0,
				"width": 11.0,
				"follow_owner": self,
				"follow_offset": origin,
			}
		)
		warnings.append(warning)
	return warnings

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

func _spawn_boss_laser_warning(
	origin: Vector2,
	direction: Vector2,
	overrides := {}
) -> BossLaserWarning:
	var warning := BossLaserWarningScene.instantiate() as BossLaserWarning
	warning.warning_width_design = 3.0
	warning.laser_width_design = 14.0
	warning.combat_bottom_margin_design = 150.0
	_spawn_parent().add_child(warning)
	warning.fire(origin, direction, "enemy", overrides)
	return warning

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

func _laser_muzzle_origin(direction: Vector2, padding_design: float) -> Vector2:
	var safe_direction := direction.normalized()
	var support_distance := _support_distance_along(safe_direction)
	return global_position + safe_direction * (
		support_distance + DisplaySettings.scale_value(padding_design)
	)

func _support_distance_along(direction: Vector2) -> float:
	var best := 0.0
	if sprite and sprite.texture:
		var half_size := Vector2(
			sprite.texture.get_width() * absf(sprite.global_scale.x) * 0.5,
			sprite.texture.get_height() * absf(sprite.global_scale.y) * 0.5
		)
		best = maxf(best, absf(direction.x) * half_size.x + absf(direction.y) * half_size.y)
	var collision_polygon := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if collision_polygon:
		for point in collision_polygon.polygon:
			var world_point := collision_polygon.to_global(point)
			best = maxf(best, direction.dot(world_point - global_position))
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		var center_offset := collision_shape.global_position - global_position
		best = maxf(
			best,
			direction.dot(center_offset)
				+ circle.radius * maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
		)
	return best

func _boss3_laser_mount_offsets() -> Array[Vector2]:
	if sprite == null or sprite.texture == null:
		return [
			DisplaySettings.to_current(Vector2(-UNITY_UNIT * 0.46, UNITY_UNIT * 0.66)),
			DisplaySettings.to_current(Vector2(UNITY_UNIT * 0.46, UNITY_UNIT * 0.66)),
		]
	var offset_scale := Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
	return [
		Vector2(-18.0 * offset_scale.x, 28.0 * offset_scale.y),
		Vector2(18.0 * offset_scale.x, 28.0 * offset_scale.y),
	]

func _boss1_half_width() -> float:
	if sprite and sprite.texture:
		var sprite_width := sprite.texture.get_size().x * sprite.scale.x * scale.x
		return max(DisplaySettings.scale_value(96.0), sprite_width * 0.5)
	return DisplaySettings.scale_value(168.0)

func _boss2_laser_sequence_active() -> bool:
	if boss_id != 2:
		return false
	if boss2_laser_warning == null:
		return false
	if not is_instance_valid(boss2_laser_warning):
		boss2_laser_warning = null
		return false
	if boss2_laser_warning.is_queued_for_deletion():
		boss2_laser_warning = null
		return false
	return true
