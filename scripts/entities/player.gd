extends CombatBody
class_name PlayerShip

signal health_changed(current: float, max_value: float)
signal weapon_changed

const DEBUG_INVINCIBLE_SETTING := "space_hero/debug/player_invincible"
const MOVE_BOUND_LEFT := 34.0
const MOVE_BOUND_RIGHT := 1886.0
const MOVE_BOUND_TOP := 48.0
const MOVE_BOUND_BOTTOM := 1032.0

@export var debug_invincible := false

var speed := 645.0
var fire_timer := 0.0
var mouse_drag := false
var drag_offset := Vector2.ZERO
var stage: Node
var friend_offsets := [Vector2(-72, 39), Vector2(72, 39)]
var friends: Array[Sprite2D] = []

const TailJetScene := preload("res://scenes/components/ship_tail_jet.tscn")

func _ready() -> void:
	setup("res://assets/sprites/Spaceship_Protagonist - P1.png", 30, "player", GameData.player_health)
	_attach_tail_jet(sprite, 0.48)
	add_to_group("player")
	died.connect(_on_died)

func _process(delta: float) -> void:
	_move(delta)
	_update_friends(delta)
	fire_timer -= delta
	if fire_timer <= 0:
		shoot_current_weapon()
	if Input.is_action_just_pressed("switch_weapon"):
		GameData.switch_bullet()
		weapon_changed.emit()

func take_damage(amount: float) -> void:
	if is_invincible():
		return
	super.take_damage(amount)
	GameData.player_health = max(0.0, health)
	health_changed.emit(health, max_health)

func is_invincible() -> bool:
	return debug_invincible or bool(ProjectSettings.get_setting(DEBUG_INVINCIBLE_SETTING, false))

func shoot_current_weapon() -> void:
	var bullet_type := GameData.current_bullet()
	var interval: float = SpaceBullet.bullet_info(bullet_type).interval
	fire_timer = interval
	_fire_pattern(bullet_type, global_position, Vector2.UP, "player")
	for i in min(GameData.friend_plane_count, friends.size()):
		_fire_pattern(bullet_type, friends[i].global_position, Vector2.UP, "player")
	var sfx_key: String = SpaceBullet.bullet_info(bullet_type).sfx
	AudioBus.play_sfx(sfx_key, -12.0)

func _fire_pattern(bullet_type: String, origin: Vector2, direction: Vector2, team_name: String) -> void:
	match bullet_type:
		"BulletArrow":
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(-34, -68)), Vector2(-1, -1).normalized(), team_name)
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(0, -68)), direction, team_name)
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(34, -68)), Vector2(1, -1).normalized(), team_name)
		"Bullet3":
			for offset in [-14.0, 0.0, 14.0]:
				_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(offset, -34)), direction, team_name)
		"BulletLaser":
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(0, -34)), direction, team_name)
		"Bullet2":
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(0, -68)), direction, team_name)
		_:
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(0, -34)), direction, team_name)

func _spawn_bullet(type_name: String, origin: Vector2, direction: Vector2, team_name: String) -> void:
	var bullet := SpaceBullet.new()
	_spawn_parent().add_child(bullet)
	bullet.setup(type_name, team_name, origin, direction)

func _shot_offset(design_offset: Vector2) -> Vector2:
	return DisplaySettings.to_current(design_offset)

func _move(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse := get_global_mouse_position()
		if not mouse_drag and global_position.distance_to(mouse) < DisplaySettings.scale_value(70):
			mouse_drag = true
			drag_offset = global_position - mouse
		if mouse_drag:
			global_position = mouse + drag_offset
	else:
		mouse_drag = false
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	global_position += input * DisplaySettings.scale_value(speed) * delta
	global_position.x = clamp(global_position.x, DisplaySettings.scale_value(MOVE_BOUND_LEFT), DisplaySettings.scale_value(MOVE_BOUND_RIGHT))
	global_position.y = clamp(global_position.y, DisplaySettings.scale_value(MOVE_BOUND_TOP), DisplaySettings.scale_value(MOVE_BOUND_BOTTOM))

func sync_friends() -> void:
	while friends.size() < GameData.friend_plane_count:
		var friend := Sprite2D.new()
		friend.texture = load("res://assets/sprites/friendplane.png")
		friend.scale = Vector2.ONE * 0.30 * DisplaySettings.scale_factor()
		_attach_tail_jet(friend, 1.55)
		_spawn_parent().add_child(friend)
		friends.append(friend)

func _update_friends(delta: float) -> void:
	sync_friends()
	for i in friends.size():
		friends[i].global_position = friends[i].global_position.lerp(global_position + DisplaySettings.to_current(friend_offsets[i]), min(1.0, delta * 8.0))

func _on_died(_body: CombatBody) -> void:
	await get_tree().create_timer(0.8).timeout
	SceneFlow.go_game_over()

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root

func _attach_tail_jet(target_sprite: Sprite2D, jet_scale: float) -> void:
	if target_sprite == null or target_sprite.get_node_or_null("TailJet") != null:
		return
	var tail_jet := TailJetScene.instantiate() as Node2D
	tail_jet.name = "TailJet"
	tail_jet.position = Vector2(0, 22)
	tail_jet.scale = Vector2.ONE * jet_scale
	target_sprite.add_child(tail_jet)
