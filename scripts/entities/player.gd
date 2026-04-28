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
var friends: Array[Sprite2D] = []
var friend_laser_timers: Array[float] = []
var friend_orbit_angle := 0.0
var victory_fly_active := false

const TailJetScene := preload("res://scenes/components/ship_tail_jet.tscn")
const FriendLaserScene := preload("res://scenes/components/friend_laser_beam.tscn")
const FRIEND_ORBIT_X_RADIUS := 66.0
const FRIEND_ORBIT_Y_RADIUS := 88.0
const FRIEND_ORBIT_SPEED := 2.0
const FRIEND_LASER_INTERVAL := 1.05
const FRIEND_VISUAL_SCALE := 1.2
const FRIEND_TAIL_JET_SCALE := 0.58
const VICTORY_FLY_SPEED := 540.0
const MISSILE_PARALLEL_SPACING := 34.0

func _ready() -> void:
	setup("res://assets/sprites/Spaceship_Protagonist - P1.png", 30, "player", GameData.player_health)
	_attach_tail_jet(sprite, 0.48)
	add_to_group("player")
	died.connect(_on_died)

func _process(delta: float) -> void:
	if victory_fly_active:
		_process_victory_fly(delta)
		return
	if dead:
		return
	_move(delta)
	_update_friends(delta)
	fire_timer -= delta
	if fire_timer <= 0:
		shoot_current_weapon()
	if Input.is_action_just_pressed("switch_weapon"):
		GameData.switch_bullet()
		weapon_changed.emit()

func take_damage(amount: float, hit_position := Vector2.ZERO, use_hit_position := false) -> void:
	if is_invincible():
		return
	super.take_damage(amount, hit_position, use_hit_position)
	GameData.player_health = max(0.0, health)
	health_changed.emit(health, max_health)

func is_invincible() -> bool:
	return debug_invincible or bool(ProjectSettings.get_setting(DEBUG_INVINCIBLE_SETTING, false))

func start_victory_fly() -> void:
	victory_fly_active = true
	debug_invincible = true
	mouse_drag = false
	fire_timer = 999999.0
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	var polygon := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon:
		polygon.set_deferred("disabled", true)

func shoot_current_weapon() -> void:
	var bullet_type := GameData.current_bullet()
	var interval: float = SpaceBullet.bullet_info(bullet_type).interval
	fire_timer = interval / GameData.weapon_fire_rate_multiplier(bullet_type)
	_fire_pattern(bullet_type, global_position, Vector2.UP, "player")
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
		"BulletMissile":
			var missile_count := GameData.missile_parallel_count()
			var center := (float(missile_count) - 1.0) * 0.5
			for i in missile_count:
				var offset_x := (float(i) - center) * MISSILE_PARALLEL_SPACING
				_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(offset_x, -68)), direction, team_name)
		_:
			_spawn_bullet(bullet_type, origin + _shot_offset(Vector2(0, -34)), direction, team_name)

func _spawn_bullet(type_name: String, origin: Vector2, direction: Vector2, team_name: String) -> void:
	var bullet := SpaceBullet.create(type_name)
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
		friend.scale = Vector2.ONE * FRIEND_VISUAL_SCALE * DisplaySettings.scale_factor()
		_attach_tail_jet(friend, FRIEND_TAIL_JET_SCALE)
		_spawn_parent().add_child(friend)
		var index := friends.size()
		var count: int = max(GameData.friend_plane_count, 1)
		friend.global_position = global_position + _friend_orbit_offset(TAU * float(index) / float(count))
		friends.append(friend)
		friend_laser_timers.append(0.25 + float(index) * 0.33)

func _update_friends(delta: float) -> void:
	sync_friends()
	var active_count: int = min(GameData.friend_plane_count, friends.size())
	if active_count > 0:
		friend_orbit_angle -= FRIEND_ORBIT_SPEED * delta
	for i in friends.size():
		var friend := friends[i]
		friend.visible = i < active_count
		if not friend.visible:
			continue
		var angle := friend_orbit_angle + TAU * float(i) / float(active_count)
		friend.global_position = global_position + _friend_orbit_offset(angle)
		friend.rotation = 0.0
		friend_laser_timers[i] -= delta
		if not victory_fly_active and friend_laser_timers[i] <= 0.0:
			friend_laser_timers[i] = FRIEND_LASER_INTERVAL + float(i) * 0.18
			_fire_friend_laser(friend)

func _on_died(_body: CombatBody) -> void:
	await get_tree().create_timer(0.8).timeout
	SceneFlow.go_game_over()

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root

func _process_victory_fly(delta: float) -> void:
	global_position += Vector2.UP * DisplaySettings.scale_value(VICTORY_FLY_SPEED) * delta
	_update_friends(delta)

func _friend_orbit_offset(angle: float) -> Vector2:
	return Vector2(
		cos(angle) * DisplaySettings.scale_value(FRIEND_ORBIT_X_RADIUS),
		sin(angle) * DisplaySettings.scale_value(FRIEND_ORBIT_Y_RADIUS)
	)

func _fire_friend_laser(friend: Sprite2D) -> void:
	var laser := FriendLaserScene.instantiate()
	_spawn_parent().add_child(laser)
	if laser.has_method("fire_from_anchor"):
		laser.call(
			"fire_from_anchor",
			friend,
			DisplaySettings.to_current(Vector2(0, -32)),
			Vector2.UP,
			"player",
			{"width": 9.0, "damage": 1.0, "life": 0.70, "extend_to_edge": true}
		)
	elif laser.has_method("fire"):
		laser.call("fire", friend.global_position + DisplaySettings.to_current(Vector2(0, -28)), Vector2.UP, "player")
	AudioBus.play_sfx("laser", -20.0)

func _attach_tail_jet(target_sprite: Sprite2D, jet_scale: float) -> void:
	if target_sprite == null or target_sprite.get_node_or_null("TailJet") != null:
		return
	var tail_jet := TailJetScene.instantiate() as Node2D
	tail_jet.name = "TailJet"
	tail_jet.position = Vector2(0, 22)
	tail_jet.scale = Vector2.ONE * jet_scale
	target_sprite.add_child(tail_jet)
