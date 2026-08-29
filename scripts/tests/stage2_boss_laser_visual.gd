extends Node

const STAGE_SCENE := preload("res://scenes/stage_2.tscn")


func _ready() -> void:
	var stage := STAGE_SCENE.instantiate()
	add_child(stage)
	await get_tree().process_frame
	stage.call("_debug_clear_combat")
	stage.call("_spawn_boss", 2)
	var boss := stage.get("boss") as BossShip
	var player := stage.get("player") as Node2D
	var display_settings := stage.get_node("/root/DisplaySettings")
	if boss and player:
		boss.global_position = display_settings.call("to_current", Vector2(1180, 240))
		player.global_position = display_settings.call("to_current", Vector2(1020, 910))
		boss.call("_shoot_boss2_laser")
	await get_tree().create_timer(2.5).timeout
	get_tree().quit()
