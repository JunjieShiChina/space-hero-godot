extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame
	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)

	var stage := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	stage.call("_spawn_boss", 1)
	await get_tree().process_frame
	var boss := stage.get("boss") as Node2D
	if boss:
		boss.global_position = display_settings.call("to_current", Vector2(960, 220))
		boss.call("take_damage", 1000.0)
	await get_tree().process_frame
	await get_tree().create_timer(0.12).timeout
	_save_snapshot("res://tests/output/boss_bar_verify_half.png")

	if boss:
		boss.call("take_damage", float(boss.get("health")) + 1000.0)
	await get_tree().process_frame
	var reward_count := 0
	for child in stage.get_children():
		if child is PickupItem and String(child.get("kind")).begins_with("coin"):
			reward_count += 1
	print("boss_reward_coins=", reward_count)

	var shield_item := (load("res://scenes/entities/shop_items/shop_shield.tscn") as PackedScene).instantiate()
	stage.add_child(shield_item)
	if shield_item.has_method("configure_from_definition"):
		shield_item.call("configure_from_definition", shield_item, display_settings.call("to_current", Vector2(960, 650)), 0.0, stage)

	await get_tree().create_timer(0.25).timeout
	_save_snapshot("res://tests/output/boss_death_verify_early.png")
	await get_tree().create_timer(0.95).timeout
	_save_snapshot("res://tests/output/boss_death_verify_mid.png")
	await get_tree().create_timer(1.35).timeout
	_save_snapshot("res://tests/output/boss_death_verify_late.png")

	stage.call("_debug_clear_combat", true)
	stage.queue_free()
	await get_tree().process_frame


func _save_snapshot(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var image := get_tree().root.get_texture().get_image()
	if image:
		image.save_png(path)
