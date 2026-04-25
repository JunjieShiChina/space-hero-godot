extends Node2D

@export var stage_number := 1

const HudScene := preload("res://scripts/ui/hud.gd")
const StarfieldScene := preload("res://scenes/components/starfield_particles.tscn")

var player: PlayerShip
var hud: BattleHud
var boss: BossShip
var elapsed := 0.0
var ship_accum := 0.0
var ep2_accum := 0.0
var meteor_enemy_accum := 0.0
var meteor_accum := 0.0
var pickup_accum := 0.0
var rotation_spawned := false
var small_boss_spawned := false
var boss_spawned := false
var warning_sent := false
var stage_done := false

var configs := {
	1: {"boss_time": 120.0, "ship_delay": 0.0, "ship_prob": 0.8, "ep2_delay": 10.0, "ep2_prob": 0.6, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.1, "meteor_delay": 0.0, "meteor_prob": 0.15, "small_boss_delay": 0.0, "boss": 1},
	2: {"boss_time": 180.0, "ship_delay": 10.0, "ship_prob": 0.6, "ep2_delay": 20.0, "ep2_prob": 0.8, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.2, "meteor_delay": 0.0, "meteor_prob": 0.15, "small_boss_delay": 120.0, "boss": 2},
	3: {"boss_time": 180.0, "ship_delay": 10.0, "ship_prob": 0.6, "ep2_delay": 20.0, "ep2_prob": 0.8, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.2, "meteor_delay": 0.0, "meteor_prob": 0.15, "small_boss_delay": 120.0, "boss": 3},
}

func _ready() -> void:
	randomize()
	AudioBus.play_music("stage")
	_create_camera()
	_create_background()
	_create_hud()
	_create_player()
	_create_shop()

func _process(delta: float) -> void:
	if stage_done:
		return
	elapsed += delta
	ship_accum += delta
	ep2_accum += delta
	meteor_enemy_accum += delta
	meteor_accum += delta
	pickup_accum += delta
	var cfg: Dictionary = configs[stage_number]
	if pickup_accum >= 12:
		pickup_accum = 0
		_spawn_pickup()
	if not warning_sent:
		_update_enemy_spawns(cfg)
	if not warning_sent and elapsed >= cfg.boss_time:
		warning_sent = true
		AudioBus.play_sfx("warning")
		hud.show_warning("WARNING")
	if not boss_spawned and elapsed >= cfg.boss_time + 6.0:
		_spawn_boss(cfg.boss)

func update_boss_health(ratio: float) -> void:
	if hud:
		hud.update_boss(ratio)

func on_boss_defeated() -> void:
	if stage_done:
		return
	stage_done = true
	hud.show_boss_bar(false)
	AudioBus.play_sfx("success")
	await get_tree().create_timer(2.0).timeout
	SceneFlow.finish_stage()

func spawn_shield() -> void:
	var shield := ShieldBubble.new()
	add_child(shield)
	shield.configure(player)

func _create_camera() -> void:
	var camera := Camera2D.new()
	camera.position = DisplaySettings.logical_center()
	add_child(camera)
	camera.make_current()

func _create_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -100
	add_child(background_layer)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	background_layer.add_child(bg)
	var starfield := StarfieldScene.instantiate()
	starfield.name = "Starfield"
	background_layer.add_child(starfield)

func _create_hud() -> void:
	hud = HudScene.new()
	add_child(hud)

func _create_player() -> void:
	player = PlayerShip.new()
	add_child(player)
	player.stage = self
	player.global_position = DisplaySettings.to_current(Vector2(960, 900))
	player.health_changed.connect(hud.set_player_health)
	player.weapon_changed.connect(hud.refresh)

func _create_shop() -> void:
	var goods := [
		["bullet", 40, "BulletArrow", DisplaySettings.to_current(Vector2(1545, 885))],
		["bullet", 70, "Bullet3", DisplaySettings.to_current(Vector2(1702.5, 885))],
		["friend", 90, "", DisplaySettings.to_current(Vector2(1545, 1012.5))],
		["shield", 110, "", DisplaySettings.to_current(Vector2(1702.5, 1012.5))],
	]
	for g in goods:
		var item := PickupItem.new()
		add_child(item)
		item.stage = self
		item.configure_goods(g[3], g[0], g[1], g[2])

func _update_enemy_spawns(cfg: Dictionary) -> void:
	if ship_accum >= 1.0:
		ship_accum = 0
		if elapsed >= cfg.ship_delay and randf() <= cfg.ship_prob:
			_spawn_enemy("ship")
	if ep2_accum >= 1.0:
		ep2_accum = 0
		if elapsed >= cfg.ep2_delay and randf() <= cfg.ep2_prob:
			_spawn_enemy("ep2")
	if meteor_enemy_accum >= 1.0:
		meteor_enemy_accum = 0
		if elapsed >= cfg.meteor_enemy_delay and randf() <= cfg.meteor_enemy_prob:
			_spawn_enemy("meteor_enemy")
	if meteor_accum >= 0.5:
		meteor_accum = 0
		if elapsed >= cfg.meteor_delay and randf() <= cfg.meteor_prob:
			_spawn_enemy("meteor")
	if not rotation_spawned and elapsed >= cfg.rotation_delay:
		rotation_spawned = true
		if randf() <= cfg.rotation_prob:
			_spawn_rotation_pair()
	if not small_boss_spawned and elapsed >= cfg.small_boss_delay:
		small_boss_spawned = true
		_spawn_enemy("small_boss")

func _spawn_rotation_pair() -> void:
	_spawn_enemy_at("rotation_ep", Vector2(_unity_x_to_screen(-1.5), DisplaySettings.scale_value(-90)))
	_spawn_enemy_at("rotation_ep", Vector2(_unity_x_to_screen(1.5), DisplaySettings.scale_value(-90)))

func _spawn_enemy(kind: String) -> void:
	_spawn_enemy_at(kind, Vector2(randf_range(DisplaySettings.scale_value(105), DisplaySettings.scale_value(1815)), DisplaySettings.scale_value(-90)))

func _spawn_enemy_at(kind: String, pos: Vector2) -> void:
	var enemy := EnemyShip.new()
	add_child(enemy)
	enemy.configure(kind, pos, player)
	enemy.died.connect(_on_enemy_died)

func _unity_x_to_screen(unity_x: float) -> float:
	return DisplaySettings.scale_value(960.0 + unity_x * 192.0)

func _spawn_boss(id: int) -> void:
	boss_spawned = true
	AudioBus.play_music("boss")
	hud.show_boss_bar(true)
	boss = BossShip.new()
	add_child(boss)
	boss.configure(id, player, self)

func _spawn_pickup() -> void:
	var item := PickupItem.new()
	add_child(item)
	if randf() < 0.2:
		item.configure_hp(Vector2(randf_range(DisplaySettings.scale_value(120), DisplaySettings.scale_value(1800)), DisplaySettings.scale_value(-60)))
	else:
		var type_name: String = ["coin1", "coin2", "coin3"].pick_random()
		var value: int = 10 if type_name == "coin1" else 20 if type_name == "coin2" else 30
		item.configure_coin(type_name, Vector2(randf_range(DisplaySettings.scale_value(120), DisplaySettings.scale_value(1800)), DisplaySettings.scale_value(-60)), value)

func _on_enemy_died(enemy: CombatBody) -> void:
	if randf() < enemy.coin_drop_chance:
		var coin := PickupItem.new()
		add_child(coin)
		var type_name: String = ["coin1", "coin2", "coin3"].pick_random()
		var value: int = 10 if type_name == "coin1" else 20 if type_name == "coin2" else 30
		coin.configure_coin(type_name, enemy.global_position, value)
	elif randf() < enemy.hp_drop_chance:
		var hp := PickupItem.new()
		add_child(hp)
		hp.configure_hp(enemy.global_position)
