extends SceneTree

func _initialize() -> void:
	var paths := [
		"res://addons/hasturoperationgd/hasturoperationgd.gd",
		"res://addons/hasturoperationgd/executor_backend.gd",
		"res://addons/hasturoperationgd/executor_dock.gd",
		"res://addons/hasturoperationgd/hastur_operation_gd_plugin_settings.gd",
	]
	for path in paths:
		print("LOADING ", path)
		var script := load(path)
		print("  -> ", script)
	quit()
