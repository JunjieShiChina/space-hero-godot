extends Node

const STAGE_SCENE := preload("res://scenes/stage_3.tscn")
const OUTPUT_DIR := "res://tests/output/stage3_boss_laser_follow"

var _stage: Node = null
var _boss: BossShip = null
var _player: Node2D = null
var _display_settings: Node = null


func _ready() -> void:
	await _setup_scene()
	var warnings := _boss.call("_shoot_boss3_lasers") as Array
	await get_tree().process_frame
	_save_frame("warning_start.png")
	_boss.global_position += _display_settings.call("to_current", Vector2(140, 0))
	_align_player_to_left_laser()
	await get_tree().process_frame
	_save_frame("warning_follow.png")
	for warning in warnings:
		warning.call("_process", 1.02)
	await get_tree().process_frame
	for child in _boss.get_parent().get_children():
		if child is SpaceBullet and String(child.get("bullet_type")) == "BulletLaser":
			child.call("_physics_process", 0.08)
	await get_tree().process_frame
	_save_frame("laser_active.png")
	_boss.global_position += _display_settings.call("to_current", Vector2(-200, 0))
	_align_player_to_left_laser()
	for child in _boss.get_parent().get_children():
		if child is SpaceBullet and String(child.get("bullet_type")) == "BulletLaser":
			child.call("_physics_process", 0.08)
	await get_tree().process_frame
	_save_frame("laser_follow.png")
	get_tree().quit()


func _setup_scene() -> void:
	_display_settings = get_node("/root/DisplaySettings")
	_display_settings.call("set_resolution", 0)
	_stage = STAGE_SCENE.instantiate()
	add_child(_stage)
	await get_tree().process_frame
	_stage.call("_debug_clear_combat", true)
	_stage.call("_spawn_boss", 3)
	await get_tree().process_frame
	await get_tree().process_frame
	_boss = _stage.get("boss") as BossShip
	_player = _stage.get("player") as Node2D
	if _boss:
		_boss.global_position = _display_settings.call("to_current", Vector2(960, 220))
	if _player:
		_align_player_to_left_laser()


func _align_player_to_left_laser() -> void:
	if _boss == null or _player == null:
		return
	var mount_offsets := _boss.call("_boss3_laser_mount_offsets") as Array
	var player_position := Vector2(960.0, 900.0)
	if mount_offsets != null and not mount_offsets.is_empty():
		var left_mount := mount_offsets[0] as Vector2
		var left_world := _boss.to_global(left_mount)
		player_position.x = left_world.x / _display_settings.call("scale_factor")
	_player.global_position = _display_settings.call("to_current", player_position)


func _save_frame(file_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name)))
