extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame

	var stage_scene := load("res://scenes/stage_1.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	stage.call("debug_jump_to_phase", "boss_warning")
	await get_tree().process_frame
	assert(bool(stage.get("warning_sent")))
	assert(not bool(stage.get("boss_spawned")))

	stage.call("debug_jump_to_phase", "boss")
	await get_tree().process_frame
	assert(bool(stage.get("boss_spawned")))
	assert(stage.get("boss") != null)

	print("debug_stage_jump warning_sent=", stage.get("warning_sent"), " boss_spawned=", stage.get("boss_spawned"))

	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.25).timeout
		var image := get_tree().root.get_texture().get_image()
		if image:
			image.save_png("res://tests/output/debug_stage_jump_verify.png")

	stage.call("_debug_clear_combat", true)
	stage.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
