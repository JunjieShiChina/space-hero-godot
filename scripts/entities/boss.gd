extends CombatBody
class_name BossShip

var boss_id := 1
var player: PlayerShip
var stage: Node
var shoot_timer := 1.0
var special_timer := 3.0
var target := Vector2.ZERO
var laser_nodes: Array[SpaceBullet] = []

func configure(id: int, target_player: PlayerShip, owner_stage: Node) -> void:
	boss_id = id
	player = target_player
	stage = owner_stage
	var texture := "res://assets/sprites/boss1.png"
	var hp := 900.0
	if id == 2:
		texture = "res://assets/sprites/Spaceship_Boss 1.png"
		hp = 1200.0
	elif id == 3:
		texture = "res://assets/sprites/Spaceship_Boss 3.png"
		hp = 1500.0
	global_position = DisplaySettings.to_current(Vector2(960, -195))
	setup(texture, 84, "enemy", hp)
	stat_key = "boss%d" % id
	add_to_group("enemy")
	died.connect(_on_boss_died)
	target = DisplaySettings.to_current(Vector2(960, 202.5))

func _process(delta: float) -> void:
	if dead:
		return
	_move(delta)
	shoot_timer -= delta
	special_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = 1.0 if boss_id != 1 else 1.25
		_shoot_primary()
	if special_timer <= 0:
		special_timer = 4.0
		_shoot_special()
	if stage and stage.has_method("update_boss_health"):
		stage.update_boss_health(health / max_health)

func _move(delta: float) -> void:
	match boss_id:
		1:
			target = DisplaySettings.to_current(Vector2(255 + abs(sin(Time.get_ticks_msec() * 0.0006)) * 1410, 217.5))
		2:
			if global_position.distance_to(target) < DisplaySettings.scale_value(18):
				target = Vector2(
					randf_range(DisplaySettings.scale_value(240), DisplaySettings.scale_value(1680)),
					randf_range(DisplaySettings.scale_value(142.5), DisplaySettings.scale_value(390))
				)
		3:
			if player:
				target = Vector2(clamp(player.global_position.x, DisplaySettings.scale_value(240), DisplaySettings.scale_value(1680)), DisplaySettings.scale_value(195))
	global_position = global_position.move_toward(target, delta * DisplaySettings.scale_value(165 + boss_id * 60))

func _shoot_primary() -> void:
	var count := 10 if boss_id == 1 else 18 if boss_id == 2 else 16
	var spread := 100.0 if boss_id != 2 else 360.0
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var angle := -spread / 2.0 + spread * t
		var dir := Vector2.DOWN.rotated(deg_to_rad(angle))
		var bullet_type := "Bullet2" if boss_id != 3 else "Bullet3"
		var bullet := SpaceBullet.new()
		_spawn_parent().add_child(bullet)
		bullet.setup(bullet_type, "enemy", global_position + DisplaySettings.to_current(Vector2(0, 62)), dir)

func _shoot_special() -> void:
	if boss_id == 1:
		for angle in [-50, -30, -10, 10, 30, 50]:
			var bullet := SpaceBullet.new()
			_spawn_parent().add_child(bullet)
			bullet.setup("BulletYue", "enemy", global_position + DisplaySettings.to_current(Vector2(0, 66)), Vector2.DOWN.rotated(deg_to_rad(angle)))
	elif boss_id == 2:
		if player:
			var dir := (player.global_position - global_position).normalized()
			var laser := SpaceBullet.new()
			_spawn_parent().add_child(laser)
			laser.setup("BulletLaser", "enemy", global_position + dir * DisplaySettings.scale_value(165), dir)
	else:
		for offset in [-108, 108]:
			var missile := SpaceBullet.new()
			_spawn_parent().add_child(missile)
			missile.setup("BulletMissile", "enemy", global_position + DisplaySettings.to_current(Vector2(offset, 64)), Vector2.DOWN)

func _on_boss_died(_body: CombatBody) -> void:
	if stage and stage.has_method("on_boss_defeated"):
		stage.on_boss_defeated()

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
