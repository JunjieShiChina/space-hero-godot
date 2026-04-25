extends SceneTree

const SCENES := [
	"res://scenes/main_menu.tscn",
	"res://scenes/stage_1.tscn",
	"res://scenes/stage_2.tscn",
	"res://scenes/stage_3.tscn",
	"res://scenes/transition.tscn",
	"res://scenes/game_over.tscn",
	"res://scenes/thanks.tscn",
]

func _initialize() -> void:
	var failed := false
	var baseline_nodes := root.get_children()
	for path in SCENES:
		var packed := load(path)
		if packed == null:
			push_error("Failed to load %s" % path)
			failed = true
			continue
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		scene.queue_free()
		await process_frame
		for child in root.get_children():
			if not baseline_nodes.has(child):
				child.free()
	if failed:
		quit(1)
	else:
		print("SMOKE TEST PASS")
		quit(0)
