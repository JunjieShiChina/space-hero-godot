extends Node

const MENU_SCENE := preload("res://scenes/main_menu.tscn")
const OUTPUT_PATH := "res://tests/output/display_modes/main_menu_display_modes.png"


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	var menu := MENU_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var dir_path := ProjectSettings.globalize_path("res://tests/output/display_modes")
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var image := get_tree().root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
