extends SceneTree


func _initialize() -> void:
	var stage_scene := load("res://scenes/stage_1.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame

	stage.call("spawn_shield")
	await process_frame
	var shield := _active_shield(stage)
	if shield == null:
		push_error("Expected first shield spawn to create one active shield.")
		quit(1)
		return

	var game_data := root.get_node("GameData")
	shield.set("health", 25.0)
	game_data.call("set_shield", float(shield.get("health")), float(shield.get("max_health")))
	stage.call("spawn_shield")
	await process_frame

	var active_count := _active_shield_count(stage)
	var reset_shield := _active_shield(stage)
	var failed := false
	if active_count != 1:
		push_error("Expected one active shield, found %d." % active_count)
		failed = true
	if reset_shield == null or not is_equal_approx(
		float(reset_shield.get("health")),
		float(reset_shield.get("max_health"))
	):
		push_error("Expected shield health to reset to max health.")
		failed = true
	var shield_health := float(game_data.get("shield_health"))
	var shield_max_health := float(game_data.get("shield_max_health"))
	if not is_equal_approx(shield_health, shield_max_health):
		push_error("Expected GameData shield health to reset to max health.")
		failed = true

	stage.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("SHIELD RESET TEST PASS")
		quit(0)


func _active_shield(stage: Node) -> Node:
	for child in stage.get_children():
		if _is_shield(child) and not bool(child.get("retired")):
			return child
	return null


func _active_shield_count(stage: Node) -> int:
	var count := 0
	for child in stage.get_children():
		if _is_shield(child) and not bool(child.get("retired")):
			count += 1
	return count


func _is_shield(node: Node) -> bool:
	var script := node.get_script() as Script
	return script != null and script.resource_path == "res://scripts/entities/shield.gd"
