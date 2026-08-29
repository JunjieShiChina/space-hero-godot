extends Area2D
class_name Stage4HazardArea

@export var damage := 10.0
@export var hit_interval := 0.45

var _cooldowns: Dictionary = {}


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1


func _process(delta: float) -> void:
	if _cooldowns.is_empty():
		return
	var expired: Array[int] = []
	for key in _cooldowns.keys():
		var next_value := float(_cooldowns[key]) - delta
		if next_value <= 0.0:
			expired.append(int(key))
		else:
			_cooldowns[key] = next_value
	for key in expired:
		_cooldowns.erase(key)


func apply_tick_if_needed(target: PlayerShip, hit_position: Vector2) -> void:
	if target == null or target.dead:
		return
	var key := target.get_instance_id()
	if _cooldowns.has(key):
		return
	target.take_damage(damage, hit_position, true)
	_cooldowns[key] = hit_interval
