extends Node

const STAGE_SCENE := preload("res://scenes/stage_4.tscn")
const OUTPUT_DIR := "res://tests/output/stage4_takeoff_enemy"


func _ready() -> void:
	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)

	var stage := STAGE_SCENE.instantiate()
	add_child(stage)
	stage.set("stage4_takeoff_spawned", true)

	await get_tree().process_frame
	await get_tree().process_frame
	stage.call(
		"_spawn_enemy_at",
		"stage4_takeoff",
		display_settings.call("to_current", Vector2(960.0, -92.0))
	)

	await get_tree().create_timer(1.05).timeout
	_save_frame("grounded.png")
	await get_tree().create_timer(1.22).timeout
	_save_frame("takeoff.png")
	await get_tree().create_timer(0.78).timeout
	_save_frame("airborne.png")
	get_tree().quit()


func _save_frame(file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name)))
