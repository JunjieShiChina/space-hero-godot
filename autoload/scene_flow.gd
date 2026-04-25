extends Node

const MAIN_MENU := "res://scenes/main_menu.tscn"
const TRANSITION := "res://scenes/transition.tscn"
const GAME_OVER := "res://scenes/game_over.tscn"
const THANKS := "res://scenes/thanks.tscn"

func start_new_game() -> void:
	GameData.reset_run()
	call_deferred("_change_scene", TRANSITION)

func go_main_menu() -> void:
	call_deferred("_change_scene", MAIN_MENU)

func go_game_over() -> void:
	call_deferred("_change_scene", GAME_OVER)

func finish_stage() -> void:
	GameData.player_health = clamp(GameData.player_health, 1.0, GameData.max_health)
	if GameData.has_next_stage():
		GameData.advance_stage_index()
		call_deferred("_change_scene", TRANSITION)
	else:
		call_deferred("_change_scene", THANKS)

func continue_after_transition() -> void:
	call_deferred("_change_scene", GameData.stage_path())

func _change_scene(path: String) -> void:
	if get_tree():
		var transition_layer := get_node_or_null("/root/ScreenTransition")
		if transition_layer and transition_layer.has_method("change_scene"):
			transition_layer.call("change_scene", path)
		else:
			get_tree().change_scene_to_file(path)
