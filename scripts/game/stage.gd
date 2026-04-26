extends Node2D

@export var stage_number := 1
@export var camera_path: NodePath = ^"Camera2D"
@export var background_layer_path: NodePath = ^"BackgroundLayer"
@export var hud_path: NodePath = ^"BattleHud"
@export var player_path: NodePath = ^"Player"
@export var player_start_path: NodePath = ^"PlayerStart"
@export var shop_drop_manager_path: NodePath = ^"ShopDropManager"
@export var debug_shop_mode := false

const BattleHudScene := preload("res://scenes/ui/battle_hud.tscn")
const PlayerShipScene := preload("res://scenes/entities/player_ship.tscn")
const StarfieldScene := preload("res://scenes/components/starfield_particles.tscn")
const ScrollingBackgroundScene := preload("res://scenes/components/scrolling_background.tscn")
const BackgroundAsteroidsScene := preload("res://scenes/components/background_asteroids.tscn")
const ShopDropManagerScene := preload("res://scenes/components/shop_drop_manager.tscn")
const BossWarningScene := preload("res://scenes/components/boss_warning.tscn")
const ShieldBubbleScene := preload("res://scenes/components/shield_bubble.tscn")
const ENEMY_SCENES := {
	"ship": preload("res://scenes/entities/enemy_single_shot.tscn"),
	"ep2": preload("res://scenes/entities/enemy_dual_shot.tscn"),
	"rotation_ep": preload("res://scenes/entities/enemy_rotation_quadshot.tscn"),
	"meteor_enemy": preload("res://scenes/entities/enemy_dive_arcshot.tscn"),
	"meteor": preload("res://scenes/entities/meteor.tscn"),
	"small_boss": preload("res://scenes/entities/enemy_small_boss.tscn"),
}
const BOSS_SCENES := {
	1: preload("res://scenes/entities/boss_1.tscn"),
	2: preload("res://scenes/entities/boss_2.tscn"),
	3: preload("res://scenes/entities/boss_3.tscn"),
}
const STAGE_BACKGROUNDS := {
	1: preload("res://assets/sprites/bkblue.png"),
	2: preload("res://assets/sprites/Nebula Aqua-Pink.png"),
	3: preload("res://assets/sprites/Nebula Red.png"),
}
const STAGE_BACKGROUND_SCROLL_SPEED := {
	1: 0.035,
	2: 0.1,
	3: 0.1,
}
const DEBUG_SHOP_MODE_SETTING := "space_hero/debug/shop_mode"
const DEBUG_SHOP_COIN_GRANT := 2000

var player: PlayerShip
var hud: BattleHud
var boss: BossShip
var shop_drop_manager: Node
var elapsed := 0.0
var ship_accum := 0.0
var ep2_accum := 0.0
var meteor_enemy_accum := 0.0
var meteor_accum := 0.0
var rotation_spawned := false
var small_boss_spawned := false
var boss_spawned := false
var warning_sent := false
var stage_done := false
var _debug_shop_index := 0

var configs := {
	1: {"boss_time": 120.0, "ship_delay": 0.0, "ship_prob": 0.8, "ep2_delay": 10.0, "ep2_prob": 0.6, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.1, "meteor_delay": -1.0, "meteor_prob": 0.0, "small_boss_delay": -1.0, "boss": 1},
	2: {"boss_time": 180.0, "ship_delay": 10.0, "ship_prob": 0.6, "ep2_delay": 20.0, "ep2_prob": 0.8, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.2, "meteor_delay": -1.0, "meteor_prob": 0.0, "small_boss_delay": 120.0, "boss": 2},
	3: {"boss_time": 180.0, "ship_delay": 10.0, "ship_prob": 0.6, "ep2_delay": 20.0, "ep2_prob": 0.8, "rotation_delay": 60.0, "rotation_prob": 1.0, "meteor_enemy_delay": 0.0, "meteor_enemy_prob": 0.2, "meteor_delay": 0.0, "meteor_prob": 0.15, "small_boss_delay": 120.0, "boss": 3},
}

func _ready() -> void:
	randomize()
	AudioBus.play_music("stage")
	_ensure_camera()
	_ensure_background()
	_ensure_hud()
	_ensure_player()
	_ensure_shop_drop_manager()
	if OS.is_debug_build():
		print("Debug shop: F2 toggle, F3 drop next goods, F4 grant next goods, F5 +coins, F6 grant debug loadout.")

func _process(delta: float) -> void:
	if stage_done:
		return
	elapsed += delta
	ship_accum += delta
	ep2_accum += delta
	meteor_enemy_accum += delta
	meteor_accum += delta
	var cfg: Dictionary = configs[stage_number]
	if not warning_sent:
		_update_enemy_spawns(cfg)
	if not warning_sent and elapsed >= cfg.boss_time:
		warning_sent = true
		_show_boss_warning()
	if not boss_spawned and elapsed >= cfg.boss_time + 6.0:
		_spawn_boss(cfg.boss)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F2 and OS.is_debug_build():
		debug_shop_mode = not debug_shop_mode
		_debug_log("shop mode %s" % ("ON" if debug_shop_mode else "OFF"))
		return
	if not _is_debug_shop_enabled():
		return
	match key_event.keycode:
		KEY_F3:
			_debug_drop_next_goods()
		KEY_F4:
			_debug_grant_next_goods()
		KEY_F5:
			_debug_add_coins()
		KEY_F6:
			_debug_grant_loadout()

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
	var shield := ShieldBubbleScene.instantiate() as ShieldBubble
	add_child(shield)
	shield.configure(player)

func flash_shop_failure() -> void:
	if hud and hud.has_method("flash_coin_count"):
		hud.flash_coin_count()

func _ensure_camera() -> void:
	var camera := get_node_or_null(camera_path) as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.position = DisplaySettings.logical_center()
	camera.make_current()

func _ensure_background() -> void:
	var background_layer := get_node_or_null(background_layer_path) as CanvasLayer
	if background_layer == null:
		background_layer = CanvasLayer.new()
		background_layer.name = "BackgroundLayer"
		background_layer.layer = -100
		add_child(background_layer)
	if background_layer.get_node_or_null("ScrollingBackground") == null and background_layer.get_node_or_null("Background") == null:
		if STAGE_BACKGROUNDS.has(stage_number):
			var bg := ScrollingBackgroundScene.instantiate()
			if bg.has_method("configure"):
				bg.configure(STAGE_BACKGROUNDS[stage_number], float(STAGE_BACKGROUND_SCROLL_SPEED.get(stage_number, 0.035)))
			background_layer.add_child(bg)
		else:
			var bg := ColorRect.new()
			bg.name = "Background"
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.color = Color.BLACK
			background_layer.add_child(bg)
	if background_layer.get_node_or_null("Starfield") == null:
		var starfield := StarfieldScene.instantiate()
		starfield.name = "Starfield"
		starfield.modulate = Color(0.72, 0.86, 1.0, 0.34)
		if starfield.has_method("configure_scroll"):
			starfield.configure_scroll(float(STAGE_BACKGROUND_SCROLL_SPEED.get(stage_number, 0.035)), Vector2(0.0, -1.0))
		background_layer.add_child(starfield)
	if background_layer.get_node_or_null("BackgroundAsteroids") == null:
		var asteroids := BackgroundAsteroidsScene.instantiate()
		asteroids.name = "BackgroundAsteroids"
		background_layer.add_child(asteroids)

func _ensure_hud() -> void:
	hud = get_node_or_null(hud_path) as BattleHud
	if hud != null:
		return
	hud = BattleHudScene.instantiate() as BattleHud
	hud.name = "BattleHud"
	add_child(hud)

func _ensure_player() -> void:
	player = get_node_or_null(player_path) as PlayerShip
	if player == null:
		player = PlayerShipScene.instantiate() as PlayerShip
		player.name = "Player"
		add_child(player)
	player.stage = self
	var player_start := get_node_or_null(player_start_path) as Node2D
	if player_start:
		player.global_position = DisplaySettings.to_current(player_start.position)
	elif player.global_position.is_zero_approx():
		player.global_position = DisplaySettings.to_current(Vector2(960, 900))
	if hud and not player.health_changed.is_connected(hud.set_player_health):
		player.health_changed.connect(hud.set_player_health)
	if hud and not player.weapon_changed.is_connected(hud.refresh):
		player.weapon_changed.connect(hud.refresh)

func _ensure_shop_drop_manager() -> void:
	shop_drop_manager = get_node_or_null(shop_drop_manager_path)
	if shop_drop_manager == null:
		shop_drop_manager = ShopDropManagerScene.instantiate()
		shop_drop_manager.name = "ShopDropManager"
		add_child(shop_drop_manager)
	if "stage" in shop_drop_manager:
		shop_drop_manager.stage = self

func _is_debug_shop_enabled() -> bool:
	return debug_shop_mode or bool(ProjectSettings.get_setting(DEBUG_SHOP_MODE_SETTING, false))

func _debug_drop_next_goods() -> void:
	var definition := _debug_next_shop_definition()
	if definition == null:
		_debug_log("no shop goods definitions")
		return
	var scene := definition.get("item_scene") as PackedScene
	if scene == null and shop_drop_manager:
		scene = shop_drop_manager.get("item_scene") as PackedScene
	if scene == null:
		_debug_log("missing shop goods scene")
		return
	var item := scene.instantiate()
	if item == null:
		return
	add_child(item)
	var origin := DisplaySettings.logical_center()
	if player:
		origin = player.global_position + DisplaySettings.to_current(Vector2(0, -155))
	if item.has_method("configure_from_definition"):
		item.configure_from_definition(definition, origin, 96.0, self)
	var price := int(definition.get("price"))
	if price > 0:
		GameData.add_coins(price)
	_debug_log("dropped %s" % _debug_goods_name(definition))

func _debug_grant_next_goods() -> void:
	var definition := _debug_next_shop_definition()
	if definition == null:
		_debug_log("no shop goods definitions")
		return
	if _debug_apply_goods_definition(definition):
		_debug_log("granted %s" % _debug_goods_name(definition))

func _debug_add_coins() -> void:
	GameData.add_coins(DEBUG_SHOP_COIN_GRANT)
	_debug_log("+%d coins" % DEBUG_SHOP_COIN_GRANT)

func _debug_grant_loadout() -> void:
	GameData.add_coins(DEBUG_SHOP_COIN_GRANT)
	var definitions := _debug_shop_definitions()
	var shield_granted := false
	for definition in definitions:
		if String(definition.get("product_type")) == "shield":
			shield_granted = true
		_debug_apply_goods_definition(definition)
	while GameData.friend_plane_count < GameData.friend_plane_limit:
		if not GameData.buy_friend():
			break
	if not shield_granted:
		spawn_shield()
	if hud:
		hud.refresh()
	_debug_log("granted debug loadout")

func _debug_apply_goods_definition(definition: Node) -> bool:
	var product_type := String(definition.get("product_type"))
	match product_type:
		"bullet":
			var bullet_type := String(definition.get("bullet_type"))
			if bullet_type == "":
				return false
			GameData.equip_bullet(bullet_type)
		"friend":
			if not GameData.buy_friend():
				return false
		"shield":
			spawn_shield()
		_:
			return false
	if hud:
		hud.refresh()
	AudioBus.play_sfx("consume")
	return true

func _debug_next_shop_definition() -> Node:
	var definitions := _debug_shop_definitions()
	if definitions.is_empty():
		return null
	var definition := definitions[_debug_shop_index % definitions.size()]
	_debug_shop_index = (_debug_shop_index + 1) % definitions.size()
	return definition

func _debug_shop_definitions() -> Array[Node]:
	var definitions: Array[Node] = []
	if shop_drop_manager == null:
		return definitions
	for child in shop_drop_manager.get_children():
		var product_type := String(child.get("product_type"))
		if product_type in ["bullet", "friend", "shield"]:
			definitions.append(child)
	return definitions

func _debug_goods_name(definition: Node) -> String:
	var product_type := String(definition.get("product_type"))
	if product_type == "bullet":
		return "%s:%s" % [product_type, String(definition.get("bullet_type"))]
	return product_type

func _debug_log(message: String) -> void:
	print("[debug-shop] %s" % message)

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
		var meteor_delay := float(cfg.get("meteor_delay", -1.0))
		var meteor_prob := float(cfg.get("meteor_prob", 0.0))
		if meteor_delay >= 0.0 and meteor_prob > 0.0 and elapsed >= meteor_delay and randf() <= meteor_prob:
			_spawn_enemy("meteor")
	if not rotation_spawned and elapsed >= cfg.rotation_delay:
		rotation_spawned = true
		if randf() <= cfg.rotation_prob:
			_spawn_rotation_pair()
	var small_boss_delay := float(cfg.get("small_boss_delay", -1.0))
	if small_boss_delay >= 0.0 and not small_boss_spawned and elapsed >= small_boss_delay:
		small_boss_spawned = true
		_spawn_enemy("small_boss")

func _spawn_rotation_pair() -> void:
	_spawn_enemy_at("rotation_ep", Vector2(_unity_x_to_screen(-1.5), DisplaySettings.scale_value(-90)))
	_spawn_enemy_at("rotation_ep", Vector2(_unity_x_to_screen(1.5), DisplaySettings.scale_value(-90)))

func _spawn_enemy(kind: String) -> void:
	_spawn_enemy_at(kind, Vector2(randf_range(DisplaySettings.scale_value(105), DisplaySettings.scale_value(1815)), DisplaySettings.scale_value(-90)))

func _spawn_enemy_at(kind: String, pos: Vector2) -> void:
	var scene: PackedScene = ENEMY_SCENES.get(kind)
	if scene == null:
		push_warning("Missing enemy scene for kind: %s" % kind)
		return
	var enemy := scene.instantiate() as EnemyShip
	add_child(enemy)
	enemy.configure(kind, pos, player)
	enemy.died.connect(_on_enemy_died)

func _unity_x_to_screen(unity_x: float) -> float:
	return DisplaySettings.scale_value(960.0 + unity_x * 108.0)

func _spawn_boss(id: int) -> void:
	boss_spawned = true
	AudioBus.play_music("boss")
	hud.show_boss_bar(true)
	var scene: PackedScene = BOSS_SCENES.get(id)
	if scene == null:
		push_warning("Missing boss scene for id: %s" % id)
		return
	boss = scene.instantiate() as BossShip
	add_child(boss)
	boss.configure(id, player, self)

func _show_boss_warning() -> void:
	var warning := BossWarningScene.instantiate() as BossWarning
	add_child(warning)

func _on_enemy_died(enemy: CombatBody) -> void:
	if enemy.coin_type != "" and randf() < enemy.coin_drop_chance:
		var coin := PickupItem.new()
		add_child(coin)
		coin.configure_coin(enemy.coin_type, enemy.global_position, _coin_value(enemy.coin_type), _enemy_drop_velocity(enemy))
	elif randf() < enemy.hp_drop_chance:
		var hp := PickupItem.new()
		add_child(hp)
		hp.configure_hp(enemy.global_position)

func _coin_value(type_name: String) -> int:
	match type_name:
		"coin2":
			return 40
		"coin3":
			return 200
	return 20

func _enemy_drop_velocity(enemy: CombatBody) -> Vector2:
	if enemy is EnemyShip:
		return (enemy as EnemyShip).velocity
	return Vector2.ZERO
