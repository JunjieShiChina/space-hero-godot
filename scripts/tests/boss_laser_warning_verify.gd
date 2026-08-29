extends Node

const STAGE_2_SCENE := preload("res://scenes/stage_2.tscn")
const STAGE_3_SCENE := preload("res://scenes/stage_3.tscn")


func _ready() -> void:
	await _verify_stage2_boss_laser()
	await _verify_stage3_boss_laser()
	print("boss_laser_warning_verify PASS")
	get_tree().quit()


func _verify_stage2_boss_laser() -> void:
	var stage := STAGE_2_SCENE.instantiate()
	add_child(stage)
	await get_tree().process_frame
	stage.call("_debug_clear_combat")
	stage.call("_spawn_boss", 2)
	var boss := stage.get("boss") as BossShip
	var player := stage.get("player") as Node2D
	var display_settings := stage.get_node("/root/DisplaySettings")
	assert(boss != null)
	assert(player != null)
	boss.global_position = display_settings.call("to_current", Vector2(960, 220))
	player.global_position = display_settings.call("to_current", Vector2(960, 880))
	var parent := boss.get_parent()
	var laser_count_before := _count_bullet_lasers(parent)
	var warning := boss.call("_shoot_boss2_laser") as Node
	assert(warning != null)
	assert(warning.global_position.distance_to(boss.global_position) >= display_settings.call("scale_value", 24.0))
	var boss_position_before := boss.global_position
	boss.call("_move", 0.25)
	assert(boss.global_position.distance_to(boss_position_before) < 0.01)
	assert(_count_bullet_lasers(parent) == laser_count_before)
	warning.call("_process", 0.99)
	assert(_count_bullet_lasers(parent) == laser_count_before)
	warning.call("_process", 0.02)
	assert(bool(warning.call("has_active_laser")))
	var laser := warning.call("active_laser") as SpaceBullet
	assert(laser != null)
	laser.call("_physics_process", 0.22)
	var laser_line := laser.get_node_or_null("CoreLine") as Line2D
	assert(laser_line != null)
	var aim_direction := (player.global_position - boss.global_position).normalized()
	var player_hit_point := (player as CombatBody).closest_collision_point(laser.global_position)
	var expected_end_distance := aim_direction.dot(player_hit_point - laser.global_position)
	assert(absf(laser_line.points[1].x - expected_end_distance) <= display_settings.call("scale_value", 24.0))
	stage.queue_free()
	await get_tree().process_frame


func _verify_stage3_boss_laser() -> void:
	var stage := STAGE_3_SCENE.instantiate()
	add_child(stage)
	await get_tree().process_frame
	stage.call("_debug_clear_combat")
	stage.call("_spawn_boss", 3)
	var boss := stage.get("boss") as BossShip
	var display_settings := stage.get_node("/root/DisplaySettings")
	assert(boss != null)
	boss.global_position = display_settings.call("to_current", Vector2(960, 220))
	var parent := boss.get_parent()
	var laser_count_before := _count_bullet_lasers(parent)
	var warnings := boss.call("_shoot_boss3_lasers") as Array
	assert(warnings != null)
	assert(warnings.size() == 2)
	assert(_count_bullet_lasers(parent) == laser_count_before)
	for warning in warnings:
		var warning_node := warning as BossLaserWarning
		assert(warning_node != null)
		var start_position: Vector2 = warning_node.global_position
		boss.global_position += display_settings.call("to_current", Vector2(60, 0))
		warning_node.call("_process", 0.10)
		assert(warning_node.global_position.distance_to(start_position) > display_settings.call("scale_value", 20.0))
		warning_node.call("_process", 0.91)
	for warning in warnings:
		var warning_node := warning as BossLaserWarning
		assert(warning_node != null)
		assert(bool(warning_node.call("has_active_laser")))
		var laser := warning_node.call("active_laser") as SpaceBullet
		assert(laser != null)
		var laser_start: Vector2 = laser.global_position
		boss.global_position += display_settings.call("to_current", Vector2(45, 0))
		laser.call("_physics_process", 0.02)
		assert(laser.global_position.distance_to(laser_start) > display_settings.call("scale_value", 12.0))
	stage.queue_free()
	await get_tree().process_frame


func _count_bullet_lasers(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is SpaceBullet and String(child.get("bullet_type")) == "BulletLaser":
			count += 1
	return count


func _last_child_named(parent: Node, node_name: String) -> Node:
	for index in range(parent.get_child_count() - 1, -1, -1):
		var child := parent.get_child(index)
		if String(child.name).begins_with(node_name):
			return child
	return null
