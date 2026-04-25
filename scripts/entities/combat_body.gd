extends Area2D
class_name CombatBody

signal died(body: CombatBody)

var team := "enemy"
var max_health := 100.0
var health := 100.0
var contact_damage := 30.0
var stat_key := ""
var coin_drop_chance := 0.35
var hp_drop_chance := 0.03
var dead := false
var retired := false

const GAMEPLAY_ENTITY_SCALE := 0.62
const PLAYER_VISUAL_TARGET := 68.0
const ENEMY_VISUAL_TARGET := 56.0
const BOSS_VISUAL_TARGET := 150.0

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
	sprite.texture = load(texture_path)
	if sprite.texture:
		var target := PLAYER_VISUAL_TARGET if team == "player" else ENEMY_VISUAL_TARGET
		if hp >= 800:
			target = BOSS_VISUAL_TARGET
		target = DisplaySettings.scale_value(target)
		var size := sprite.texture.get_size()
		if size.x > 0:
			sprite.scale = Vector2.ONE * (target / max(size.x, size.y))
	if get_node_or_null("CollisionShape2D") == null:
		var shape_node := CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		shape_node.shape = CircleShape2D.new()
		add_child(shape_node)
	var shape := get_node("CollisionShape2D") as CollisionShape2D
	(shape.shape as CircleShape2D).radius = DisplaySettings.scale_value(radius * GAMEPLAY_ENTITY_SCALE)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func take_damage(amount: float) -> void:
	if dead:
		return
	health -= amount
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
	AudioBus.play_sfx("explosion")
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
	var burst := CPUParticles2D.new()
	burst.amount = 18
	burst.lifetime = 0.45
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.initial_velocity_min = 105
	burst.initial_velocity_max = 255
	burst.scale_amount_min = 3
	burst.scale_amount_max = 6
	burst.color = Color(1.0, 0.55, 0.18)
	_spawn_parent().add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	burst.finished.connect(burst.queue_free)

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

func _emit_died_signal() -> void:
	died.emit(self)

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
