extends Node

const STAGE_SCENE := preload("res://scenes/stage_1.tscn")
const OUTPUT_PATH := "res://tests/output/settings/pause_settings_overlay.png"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()
	get_tree().quit()


func _run() -> void:
	var stage := STAGE_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	stage.call("_open_pause_settings")
	await get_tree().process_frame
	await get_tree().process_frame
	var dir_path := ProjectSettings.globalize_path("res://tests/output/settings")
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var image := get_tree().root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
