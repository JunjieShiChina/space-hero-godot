extends Node

const STAGE_SCENE := preload("res://scenes/stage_1.tscn")
const OUTPUT_PATH := "res://tests/output/player_damage_number.png"


func _ready() -> void:
	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)
	var stage := STAGE_SCENE.instantiate()
	add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := stage.get("player") as PlayerShip
	if player:
		player.global_position = display_settings.call("to_current", Vector2(960, 860))
		player.take_damage(12.0, player.global_position, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	get_tree().quit()
