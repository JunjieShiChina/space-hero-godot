extends Node

const STAGE_SCENE := preload("res://scenes/stage_2.tscn")

var _stage: Node = null
var _player: Node2D = null
var _small_boss: EnemyShip = null
var _boss2: BossShip = null
var _display_settings: Node = null


func _ready() -> void:
	await _setup_scene()
	_fire_loop()


func _setup_scene() -> void:
	await get_tree().process_frame

	_display_settings = get_node("/root/DisplaySettings")
	_display_settings.call("set_resolution", 0)

	_stage = STAGE_SCENE.instantiate()
	get_tree().root.add_child(_stage)
	await get_tree().process_frame
	await get_tree().process_frame

	_player = _stage.get("player") as Node2D
	if _player:
		_player.global_position = _display_settings.call("to_current", Vector2(960, 900))

	_stage.call("_debug_clear_combat", true)
	_stage.call("_spawn_enemy_at", "small_boss", _display_settings.call("to_current", Vector2(1260, 250)))
	_stage.call("_spawn_boss", 2)
	await get_tree().process_frame
	await get_tree().process_frame

	_small_boss = _find_small_boss()
	_boss2 = _stage.get("boss") as BossShip

	if _small_boss:
		_small_boss.global_position = _display_settings.call("to_current", Vector2(1260, 250))
		_small_boss.set("velocity", Vector2.ZERO)
		_small_boss.set("can_shoot", false)
		_small_boss.set("small_boss_find_next_target", false)
		_small_boss.set("small_boss_in_move", false)

	if _boss2:
		_boss2.global_position = _display_settings.call("to_current", Vector2(720, 160))
		_boss2.set_process(false)


func _fire_loop() -> void:
	while is_inside_tree():
		_reset_layout()
		if _small_boss:
			_small_boss.call("_shoot_small_boss_laser")
		await get_tree().create_timer(0.85).timeout
		_reset_layout()
		if _boss2:
			_boss2.call("_shoot_boss2_laser")
		await get_tree().create_timer(2.65).timeout


func _reset_layout() -> void:
	if _player:
		_player.global_position = _display_settings.call("to_current", Vector2(960, 900))
	if _small_boss and is_instance_valid(_small_boss):
		_small_boss.global_position = _display_settings.call("to_current", Vector2(1260, 250))
	if _boss2 and is_instance_valid(_boss2):
		_boss2.global_position = _display_settings.call("to_current", Vector2(720, 160))


func _find_small_boss() -> EnemyShip:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyShip and String(enemy.get("ai")) == "small_boss":
			return enemy
	return null
