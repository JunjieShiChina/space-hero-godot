extends Area2D
class_name CombatBody

signal died(body: CombatBody)

var team := "enemy"
var max_health := 100.0
var health := 100.0
var contact_damage := 30.0
var stat_key := ""
var coin_drop_chance := 0.4
var coin_type := "coin1"
var hp_drop_chance := 0.02
var dead := false
var retired := false
var _authored_collision_polygons: Dictionary = {}
var _authored_circle_collisions: Dictionary = {}
var _authored_sprite_scale := Vector2.ONE

const GAMEPLAY_ENTITY_SCALE := 0.62
const PLAYER_VISUAL_TARGET := 68.0
const ENEMY_VISUAL_TARGET := 56.0
const BOSS_VISUAL_TARGET := 150.0
const ShipExplosionScene := preload("res://scenes/components/ship_explosion.tscn")
const DamageNumberScene := preload("res://scenes/components/damage_number.tscn")

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func setup(texture_path: String, radius: float, body_team: String, hp: float) -> void:
	team = body_team
	max_health = hp
	health = hp
	monitoring = true
	monitorable = true
	collision_layer = 1 if team == "player" else 2
	collision_mask = 2 | 4 | 8 | 16 | 32 if team == "player" else 1 | 4 | 32
	if get_node_or_null("Sprite2D") == null:
		var s := Sprite2D.new()
		s.name = "Sprite2D"
		add_child(s)
	sprite = get_node("Sprite2D")
	if texture_path != "":
		sprite.texture = load(texture_path)
	_authored_sprite_scale = _non_zero_scale(sprite.scale)
	if sprite.texture:
		var target := PLAYER_VISUAL_TARGET if team == "player" else ENEMY_VISUAL_TARGET
		if hp >= 800:
			target = BOSS_VISUAL_TARGET
		target = DisplaySettings.scale_value(target)
		var size := sprite.texture.get_size()
		if size.x > 0:
			sprite.scale = Vector2.ONE * (target / max(size.x, size.y))
	_configure_collision(texture_path, radius, hp)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func take_damage(amount: float, hit_position := Vector2.ZERO, use_hit_position := false) -> void:
	if dead:
		return
	health -= amount
	if team == "enemy" and amount > 0.0:
		_spawn_damage_number(amount, hit_position, use_hit_position)
	_flash_hit()
	AudioBus.play_sfx("hit", -9.0)
	if health <= 0:
		die()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)

func die() -> void:
	if dead:
		return
	dead = true
	if stat_key != "":
		GameData.record_stat(stat_key)
	_spawn_burst()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	call_deferred("_emit_died_signal")
	call_deferred("_retire")

func _on_area_entered(area: Area2D) -> void:
	if dead:
		return
	if area is CombatBody and area.team != team:
		var other := area as CombatBody
		var other_damage := other.health
		other.take_damage(health)
		take_damage(other_damage)

func _flash_hit() -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.25, 0.25), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _spawn_burst() -> void:
	var explosion := ShipExplosionScene.instantiate() as Node2D
	_spawn_parent().add_child(explosion)
	explosion.global_position = global_position
	if max_health >= 800.0:
		explosion.scale = Vector2.ONE * 1.75
	elif team == "player":
		explosion.scale = Vector2.ONE * 1.12

func _spawn_damage_number(amount: float, hit_position: Vector2, use_hit_position: bool) -> void:
	var number := DamageNumberScene.instantiate() as DamageNumber
	if number == null:
		return
	var base_position := hit_position if use_hit_position else global_position
	var spawn_position := base_position + DisplaySettings.to_current(Vector2(randf_range(-8.0, 8.0), randf_range(-10.0, -2.0)))
	number.setup(amount, spawn_position, true)
	_spawn_parent().add_child(number)

func _retire() -> void:
	if is_queued_for_deletion() or retired:
		return
	retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	var polygon := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon:
		polygon.set_deferred("disabled", true)
	visible = false
	set_process(false)
	set_physics_process(false)

func _emit_died_signal() -> void:
	died.emit(self)

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root

func _configure_collision(texture_path: String, radius: float, hp: float) -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var polygon_node := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon_node != null and polygon_node.polygon.size() >= 3:
		_apply_authored_collision_polygon(polygon_node)
		if shape_node:
			shape_node.disabled = true
		return
	if shape_node != null and shape_node.shape is CircleShape2D:
		_apply_authored_circle_collision(shape_node)
		return
	var round_collision := _uses_round_collision(texture_path)
	if round_collision:
		if polygon_node:
			polygon_node.free()
		if shape_node == null:
			shape_node = CollisionShape2D.new()
			shape_node.name = "CollisionShape2D"
			add_child(shape_node)
		if shape_node.shape == null or not shape_node.shape is CircleShape2D:
			shape_node.shape = CircleShape2D.new()
		(shape_node.shape as CircleShape2D).radius = DisplaySettings.scale_value(radius * GAMEPLAY_ENTITY_SCALE)
		shape_node.position = Vector2.ZERO
		shape_node.disabled = false
		return
	if shape_node:
		shape_node.free()
	if polygon_node == null:
		polygon_node = CollisionPolygon2D.new()
		polygon_node.name = "CollisionPolygon2D"
		add_child(polygon_node)
	polygon_node.position = Vector2.ZERO
	polygon_node.rotation = 0.0
	polygon_node.scale = Vector2.ONE
	polygon_node.polygon = _ship_collision_polygon(texture_path, hp)
	polygon_node.disabled = false

func _apply_authored_circle_collision(shape_node: CollisionShape2D) -> void:
	var key := str(shape_node.get_path())
	if not _authored_circle_collisions.has(key):
		var circle := shape_node.shape as CircleShape2D
		_authored_circle_collisions[key] = {
			"radius": circle.radius,
			"position": shape_node.position,
		}
		shape_node.shape = circle.duplicate()
	var base: Dictionary = _authored_circle_collisions[key]
	var active_circle := shape_node.shape as CircleShape2D
	var collision_scale := _authored_collision_scale()
	active_circle.radius = float(base["radius"]) * maxf(absf(collision_scale.x), absf(collision_scale.y))
	shape_node.position = _scale_point(base["position"] as Vector2, collision_scale)
	shape_node.disabled = false

func _apply_authored_collision_polygon(polygon_node: CollisionPolygon2D) -> void:
	var key := str(polygon_node.get_path())
	if not _authored_collision_polygons.has(key):
		_authored_collision_polygons[key] = polygon_node.polygon
	var base_polygon: PackedVector2Array = _authored_collision_polygons[key]
	var scaled_polygon := PackedVector2Array()
	var collision_scale := _authored_collision_scale()
	for point in base_polygon:
		scaled_polygon.append(_scale_point(point, collision_scale))
	polygon_node.position = Vector2.ZERO
	polygon_node.rotation = 0.0
	polygon_node.scale = Vector2.ONE
	polygon_node.polygon = scaled_polygon
	polygon_node.disabled = false

func _authored_collision_scale() -> Vector2:
	if sprite == null:
		return Vector2.ONE * DisplaySettings.scale_factor()
	var base_scale := _non_zero_scale(_authored_sprite_scale)
	return Vector2(sprite.scale.x / base_scale.x, sprite.scale.y / base_scale.y)

func _non_zero_scale(value: Vector2) -> Vector2:
	return Vector2(1.0 if is_zero_approx(value.x) else value.x, 1.0 if is_zero_approx(value.y) else value.y)

func _scale_point(point: Vector2, scale_value: Vector2) -> Vector2:
	return Vector2(point.x * scale_value.x, point.y * scale_value.y)

func _uses_round_collision(texture_path: String) -> bool:
	var lower := texture_path.to_lower()
	return lower.contains("meteor") or lower.contains("quadshot")

func _ship_collision_polygon(texture_path: String, hp: float) -> PackedVector2Array:
	var size := _current_sprite_size()
	var lower := texture_path.to_lower()
	if hp >= 800.0:
		return _boss_collision_polygon(size)
	if team == "player":
		return _player_collision_polygon(size)
	if lower.contains("dualshot"):
		return _wide_enemy_collision_polygon(size)
	if lower.contains("arcshot"):
		return _dive_enemy_collision_polygon(size)
	return _single_enemy_collision_polygon(size)

func _current_sprite_size() -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2.ONE * DisplaySettings.scale_value(60.0)
	return sprite.texture.get_size() * sprite.scale

func _player_collision_polygon(size: Vector2) -> PackedVector2Array:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	return PackedVector2Array([
		Vector2(0.0, -half_h * 0.96),
		Vector2(half_w * 0.28, -half_h * 0.45),
		Vector2(half_w * 0.82, half_h * 0.08),
		Vector2(half_w * 0.52, half_h * 0.62),
		Vector2(half_w * 0.18, half_h * 0.88),
		Vector2(0.0, half_h * 0.78),
		Vector2(-half_w * 0.18, half_h * 0.88),
		Vector2(-half_w * 0.52, half_h * 0.62),
		Vector2(-half_w * 0.82, half_h * 0.08),
		Vector2(-half_w * 0.28, -half_h * 0.45),
	])

func _single_enemy_collision_polygon(size: Vector2) -> PackedVector2Array:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	return PackedVector2Array([
		Vector2(0.0, -half_h * 0.92),
		Vector2(half_w * 0.34, -half_h * 0.22),
		Vector2(half_w * 0.88, half_h * 0.2),
		Vector2(half_w * 0.42, half_h * 0.58),
		Vector2(half_w * 0.18, half_h * 0.88),
		Vector2(0.0, half_h * 0.7),
		Vector2(-half_w * 0.18, half_h * 0.88),
		Vector2(-half_w * 0.42, half_h * 0.58),
		Vector2(-half_w * 0.88, half_h * 0.2),
		Vector2(-half_w * 0.34, -half_h * 0.22),
	])

func _wide_enemy_collision_polygon(size: Vector2) -> PackedVector2Array:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	return PackedVector2Array([
		Vector2(0.0, -half_h * 0.9),
		Vector2(half_w * 0.28, -half_h * 0.28),
		Vector2(half_w * 0.94, -half_h * 0.04),
		Vector2(half_w * 0.72, half_h * 0.36),
		Vector2(half_w * 0.28, half_h * 0.54),
		Vector2(half_w * 0.1, half_h * 0.86),
		Vector2(0.0, half_h * 0.68),
		Vector2(-half_w * 0.1, half_h * 0.86),
		Vector2(-half_w * 0.28, half_h * 0.54),
		Vector2(-half_w * 0.72, half_h * 0.36),
		Vector2(-half_w * 0.94, -half_h * 0.04),
		Vector2(-half_w * 0.28, -half_h * 0.28),
	])

func _dive_enemy_collision_polygon(size: Vector2) -> PackedVector2Array:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	return PackedVector2Array([
		Vector2(0.0, -half_h * 0.96),
		Vector2(half_w * 0.22, -half_h * 0.42),
		Vector2(half_w * 0.78, -half_h * 0.04),
		Vector2(half_w * 0.64, half_h * 0.42),
		Vector2(half_w * 0.18, half_h * 0.72),
		Vector2(0.0, half_h * 0.92),
		Vector2(-half_w * 0.18, half_h * 0.72),
		Vector2(-half_w * 0.64, half_h * 0.42),
		Vector2(-half_w * 0.78, -half_h * 0.04),
		Vector2(-half_w * 0.22, -half_h * 0.42),
	])

func _boss_collision_polygon(size: Vector2) -> PackedVector2Array:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	return PackedVector2Array([
		Vector2(0.0, -half_h * 0.92),
		Vector2(half_w * 0.45, -half_h * 0.55),
		Vector2(half_w * 0.96, -half_h * 0.08),
		Vector2(half_w * 0.82, half_h * 0.36),
		Vector2(half_w * 0.36, half_h * 0.72),
		Vector2(0.0, half_h * 0.92),
		Vector2(-half_w * 0.36, half_h * 0.72),
		Vector2(-half_w * 0.82, half_h * 0.36),
		Vector2(-half_w * 0.96, -half_h * 0.08),
		Vector2(-half_w * 0.45, -half_h * 0.55),
	])
