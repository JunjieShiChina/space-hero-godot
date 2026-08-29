extends Node

const STAGE_SCENE := preload("res://scenes/stage_4.tscn")
const OUTPUT_DIR := "res://tests/output/stage4_preview"


func _ready() -> void:
	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)
	var stage := STAGE_SCENE.instantiate()
	add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_save_frame("stage4_open.png")
	await get_tree().create_timer(2.2).timeout
	_save_frame("stage4_narrow.png")
	await get_tree().create_timer(3.0).timeout
	_save_frame("stage4_hazard.png")
	await get_tree().create_timer(1.2).timeout
	_save_frame("stage4_motion.png")
	get_tree().quit()


func _save_frame(file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name)))
