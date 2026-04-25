extends Area2D
class_name ShieldBubble

var target: PlayerShip
var health := 100.0
var retired := false

func configure(player: PlayerShip) -> void:
	target = player
	collision_layer = 32
	collision_mask = 2 | 8
	var ring := Polygon2D.new()
	ring.name = "Ring"
	ring.polygon = _circle_points(46, DisplaySettings.scale_value(72))
	ring.color = Color(0.2, 0.85, 1.0, 0.25)
	add_child(ring)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = DisplaySettings.scale_value(87)
	add_child(shape)

func _process(_delta: float) -> void:
	if target == null or target.dead:
		call_deferred("_retire")
	else:
		global_position = target.global_position

func reflect_bullet(bullet: SpaceBullet) -> void:
	if bullet.shooter_team == "player":
		return
	bullet.shooter_team = "player"
	bullet.velocity *= -1.15
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 32
	health -= bullet.damage
	AudioBus.play_sfx("shield")
	modulate = Color(1, 0.25, 0.25, 0.75)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
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

func _circle_points(count: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
