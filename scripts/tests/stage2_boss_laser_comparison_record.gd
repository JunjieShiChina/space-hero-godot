extends Node

const COMPARISON_SCENE := preload("res://scenes/tests/stage2_boss_laser_comparison.tscn")
const OUTPUT_DIR := "res://tests/output/stage2_boss_laser_comparison"


func _ready() -> void:
	var comparison := COMPARISON_SCENE.instantiate()
	add_child(comparison)
	await get_tree().process_frame
	await get_tree().create_timer(0.60).timeout
	_save_frame("frame_small_warning.png")
	await get_tree().create_timer(0.45).timeout
	_save_frame("frame_small_launch.png")
	await get_tree().create_timer(0.25).timeout
	_save_frame("frame_small_active.png")
	await get_tree().create_timer(1.90).timeout
	_save_frame("frame_boss_active.png")
	await get_tree().create_timer(4.8).timeout
	get_tree().quit()


func _save_frame(file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name)))
