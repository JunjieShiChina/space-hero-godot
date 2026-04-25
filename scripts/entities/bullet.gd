extends Area2D
class_name SpaceBullet

var bullet_type := "Bullet1"
var shooter_team := "player"
var velocity := Vector2.ZERO
var damage := 10.0
var life_time := 4.0
var pierce := false
var homing := false
var spin := 0.0
var retired := false

func setup(type_name: String, team: String, pos: Vector2, direction: Vector2) -> void:
	bullet_type = type_name
	shooter_team = team
	global_position = pos
	rotation = direction.angle() + PI / 2.0
	var info := bullet_info(type_name)
	damage = info.damage
	velocity = direction.normalized() * info.speed
	life_time = info.life
	pierce = info.pierce
	homing = info.homing
	spin = info.spin
	collision_layer = 4 if team == "player" else 8
	collision_mask = 2 | 32 if team == "player" else 1 | 32
	_make_visual(info)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

static func bullet_info(type_name: String) -> Dictionary:
	var map := {
		"Bullet1": {"speed": 720.0, "damage": 15.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/bullet.png", "scale": 0.18, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"Bullet2": {"speed": 430.0, "damage": 45.0, "interval": 2.0, "life": 4.0, "texture": "res://assets/sprites/bullet3.png", "scale": 0.22, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot2"},
		"BulletArrow": {"speed": 650.0, "damage": 18.0, "interval": 0.3, "life": 3.0, "texture": "res://assets/sprites/bullet4.png", "scale": 0.2, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"BulletMissile": {"speed": 380.0, "damage": 80.0, "interval": 1.5, "life": 5.0, "texture": "res://assets/sprites/spr_missile.png", "scale": 0.18, "pierce": false, "homing": false, "spin": 0.0, "sfx": "missile"},
		"BulletLaser": {"speed": 0.0, "damage": 5.0, "interval": 2.0, "life": 1.2, "texture": "res://assets/sprites/bosslaser.png", "scale": 1.0, "pierce": true, "homing": false, "spin": 0.0, "sfx": "laser"},
		"BulletFire": {"speed": 470.0, "damage": 32.0, "interval": 1.0, "life": 3.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.22, "pierce": false, "homing": false, "spin": 5.0, "sfx": "shoot"},
		"BulletYue": {"speed": 750.0, "damage": 11.0, "interval": 0.2, "life": 3.0, "texture": "res://assets/sprites/bullet6.png", "scale": 0.2, "pierce": false, "homing": false, "spin": 7.5, "sfx": "shoot"},
		"Bullet3": {"speed": 780.0, "damage": 14.0, "interval": 0.18, "life": 3.0, "texture": "res://assets/sprites/bullet3.png", "scale": 0.16, "pierce": false, "homing": false, "spin": 0.0, "sfx": "shoot"},
		"FollowBullet": {"speed": 520.0, "damage": 10.0, "interval": 0.1, "life": 4.0, "texture": "res://assets/sprites/bullet5.png", "scale": 0.16, "pierce": false, "homing": true, "spin": 4.0, "sfx": "shoot"},
	}
	return map.get(type_name, map["Bullet1"])

func _physics_process(delta: float) -> void:
	life_time -= delta
	if life_time <= 0:
		call_deferred("_retire")
		return
	if homing:
		var target := _find_target()
		if target:
			var desired := (target.global_position - global_position).normalized() * velocity.length()
			velocity = velocity.lerp(desired, 4.0 * delta)
	if velocity != Vector2.ZERO:
		global_position += velocity * delta
		rotation = velocity.angle() + PI / 2.0
	rotation += spin * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("reflect_bullet"):
		area.reflect_bullet(self)
		return
	if area is CombatBody and area.team != shooter_team:
		(area as CombatBody).take_damage(damage)
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
	visible = false
	set_process(false)
	set_physics_process(false)

func _make_visual(info: Dictionary) -> void:
	if get_node_or_null("Sprite2D") == null:
		var new_sprite := Sprite2D.new()
		new_sprite.name = "Sprite2D"
		add_child(new_sprite)
	var sprite := get_node("Sprite2D") as Sprite2D
	sprite.texture = load(info.texture)
	sprite.scale = Vector2.ONE * info.scale
	sprite.modulate = Color(0.55, 0.9, 1.0) if shooter_team == "player" else Color(1.0, 0.45, 0.45)
	if bullet_type == "BulletLaser":
		sprite.scale = Vector2(0.22, 2.5)
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = CapsuleShape2D.new()
		add_child(shape)
	var collision := get_node("CollisionShape2D") as CollisionShape2D
	if bullet_type == "BulletLaser":
		(collision.shape as CapsuleShape2D).radius = 12
		(collision.shape as CapsuleShape2D).height = 360
	else:
		(collision.shape as CapsuleShape2D).radius = 9
		(collision.shape as CapsuleShape2D).height = 28

func _find_target() -> CombatBody:
	var best: CombatBody = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is CombatBody:
			var dist := global_position.distance_squared_to(node.global_position)
			if dist < best_dist:
				best = node
				best_dist = dist
	return best
