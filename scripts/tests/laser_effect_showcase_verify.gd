extends Node

const SHOWCASE_SCENE := preload("res://scenes/tests/laser_effect_showcase.tscn")
const OUTPUT_DIR := "res://tests/output/laser_showcase/"


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	var showcase := SHOWCASE_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(showcase)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	await _save_frame("laser_showcase_public_case_01.png")
	showcase.call("_trigger_all")
	await get_tree().create_timer(0.22).timeout
	await _save_frame("laser_showcase_public_case_02.png")
	await get_tree().create_timer(0.70).timeout
	await _save_frame("laser_showcase_public_case_03.png")


func _save_frame(file_name: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var dir_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var image := tree.root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + file_name))
