extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame

	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)

	var stage_scene := load("res://scenes/stage_2.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	var player := stage.get("player") as Node2D
	if player:
		player.global_position = display_settings.call("to_current", Vector2(960, 890))

	stage.call("_debug_clear_combat", true)
	stage.call("_spawn_enemy_at", "small_boss", display_settings.call("to_current", Vector2(1300, 230)))
	await get_tree().process_frame

	var small_boss := _find_small_boss()
	if small_boss:
		small_boss.global_position = display_settings.call("to_current", Vector2(1300, 230))
		small_boss.set("velocity", Vector2.ZERO)
		small_boss.set("can_shoot", false)
		small_boss.call("_shoot_small_boss_laser")

	await get_tree().create_timer(2.4).timeout


func _find_small_boss() -> EnemyShip:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyShip and String(enemy.get("ai")) == "small_boss":
			return enemy
	return null
