extends CombatBody
class_name EnemyShip

var velocity := Vector2.ZERO
var ai := "drift"
var shoot_timer := 1.3
var shoot_interval := 1.4
var bullet_type := "Bullet1"
var player: PlayerShip

func configure(kind: String, pos: Vector2, target: PlayerShip) -> void:
	player = target
	var config := {
		"ship": ["res://assets/sprites/Spaceship_Enemy - SingleShot.png", 20.0, 25.0, "ship", Vector2(randf_range(-135, 135), randf_range(135, 225)), "drift", "Bullet2", 2.0],
		"ep2": ["res://assets/sprites/ep2.png", 10.0, 26.0, "ep2", Vector2(randf_range(-135, 135), randf_range(135, 225)), "chase", "Bullet2", 2.0],
		"rotation_ep": ["res://assets/sprites/Spaceship_Enemy - ArcShot.png", 50.0, 30.0, "rotation_ep", Vector2(0, 120), "rotate", "BulletYue", 0.2],
		"meteor_enemy": ["res://assets/sprites/meteor0001.png", 90.0, 28.0, "meteor_enemy", Vector2(0, randf_range(225, 390)), "meteor", "Bullet1"],
		"meteor": ["res://assets/sprites/Asteroids 01.png", 80.0, 30.0, "meteor", Vector2(0, randf_range(240, 420)), "meteor", "Bullet1"],
		"small_boss": ["res://assets/sprites/Spaceship_Enemy - QuadShot.png", 500.0, 40.0, "small_boss", Vector2(0, 105), "small_boss", "Bullet2", 2.0],
	}
	var c: Array = config[kind]
	global_position = pos
	setup(c[0], c[2], "enemy", c[1])
	stat_key = c[3]
	velocity = DisplaySettings.to_current(c[4])
	ai = c[5]
	bullet_type = c[6]
	shoot_interval = c[7] if c.size() > 7 else 1.4
	shoot_timer = min(shoot_timer, shoot_interval)
	rotation = PI
	add_to_group("enemy")

func _process(delta: float) -> void:
	match ai:
		"chase":
			if player and not player.dead and global_position.distance_to(player.global_position) < DisplaySettings.scale_value(540):
				velocity = (player.global_position - global_position).normalized() * DisplaySettings.scale_value(285.0)
				rotation = velocity.angle() + PI / 2.0
		"rotate":
			rotation += delta * 2.2
		"small_boss":
			velocity.x = DisplaySettings.scale_value(sin(Time.get_ticks_msec() * 0.002) * 210)
			velocity.y = DisplaySettings.scale_value(60)
		"meteor":
			rotation += delta * 2.0
	global_position += velocity * delta
	shoot_timer -= delta
	if shoot_timer <= 0 and ai != "meteor":
		shoot_timer = shoot_interval
		_shoot()
	if global_position.y > DisplaySettings.scale_value(1230) or global_position.x < DisplaySettings.scale_value(-180) or global_position.x > DisplaySettings.scale_value(2100):
		_retire()

func _shoot() -> void:
	var base := Vector2.DOWN
	if ai == "rotate":
		base = Vector2.UP.rotated(rotation)
	elif player:
		base = (player.global_position - global_position).normalized()
	var angles := [0.0]
	if ai == "small_boss":
		angles = [-36.0, -18.0, 0.0, 18.0, 36.0]
	for a in angles:
		var bullet := SpaceBullet.new()
		_spawn_parent().add_child(bullet)
		bullet.setup(bullet_type, "enemy", global_position + DisplaySettings.to_current(Vector2(0, 32)), base.rotated(deg_to_rad(a)))

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
