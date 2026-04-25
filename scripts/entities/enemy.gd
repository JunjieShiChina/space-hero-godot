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
		"ship": ["res://assets/sprites/Spaceship_Enemy - SingleShot.png", 20.0, 28.0, "ship", Vector2(randf_range(-90, 90), randf_range(90, 150)), "drift", "Bullet2", 2.0],
		"ep2": ["res://assets/sprites/ep2.png", 10.0, 30.0, "ep2", Vector2(randf_range(-90, 90), randf_range(90, 150)), "chase", "Bullet2", 2.0],
		"rotation_ep": ["res://assets/sprites/Spaceship_Enemy - ArcShot.png", 50.0, 34.0, "rotation_ep", Vector2(0, 80), "rotate", "BulletYue", 0.2],
		"meteor_enemy": ["res://assets/sprites/meteor0001.png", 90.0, 32.0, "meteor_enemy", Vector2(0, randf_range(150, 260)), "meteor", "Bullet1"],
		"meteor": ["res://assets/sprites/Asteroids 01.png", 80.0, 34.0, "meteor", Vector2(0, randf_range(160, 280)), "meteor", "Bullet1"],
		"small_boss": ["res://assets/sprites/Spaceship_Enemy - QuadShot.png", 500.0, 46.0, "small_boss", Vector2(0, 70), "small_boss", "Bullet2", 2.0],
	}
	var c: Array = config[kind]
	global_position = pos
	setup(c[0], c[2], "enemy", c[1])
	stat_key = c[3]
	velocity = c[4]
	ai = c[5]
	bullet_type = c[6]
	shoot_interval = c[7] if c.size() > 7 else 1.4
	shoot_timer = min(shoot_timer, shoot_interval)
	rotation = PI
	add_to_group("enemy")

func _process(delta: float) -> void:
	match ai:
		"chase":
			if player and not player.dead and global_position.distance_to(player.global_position) < 360:
				velocity = (player.global_position - global_position).normalized() * 190.0
				rotation = velocity.angle() + PI / 2.0
		"rotate":
			rotation += delta * 2.2
		"small_boss":
			velocity.x = sin(Time.get_ticks_msec() * 0.002) * 140
			velocity.y = 40
		"meteor":
			rotation += delta * 2.0
	global_position += velocity * delta
	shoot_timer -= delta
	if shoot_timer <= 0 and ai != "meteor":
		shoot_timer = shoot_interval
		_shoot()
	if global_position.y > 820 or global_position.x < -120 or global_position.x > 1400:
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
		bullet.setup(bullet_type, "enemy", global_position + Vector2(0, 40), base.rotated(deg_to_rad(a)))

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
