extends CombatBody
class_name PlayerShip

signal health_changed(current: float, max_value: float)
signal weapon_changed

var speed := 430.0
var fire_timer := 0.0
var mouse_drag := false
var drag_offset := Vector2.ZERO
var stage: Node
var friend_offsets := [Vector2(-86, 44), Vector2(86, 44)]
var friends: Array[Sprite2D] = []

func _ready() -> void:
	setup("res://assets/sprites/Spaceship_Protagonist - P1.png", 34, "player", GameData.player_health)
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
	super.take_damage(amount)
	GameData.player_health = max(0.0, health)
	health_changed.emit(health, max_health)

func shoot_current_weapon() -> void:
	var bullet_type := GameData.current_bullet()
	var interval: float = SpaceBullet.bullet_info(bullet_type).interval
	fire_timer = interval
	_fire_pattern(bullet_type, global_position + Vector2(0, -42), Vector2.UP, "player")
	for i in min(GameData.friend_plane_count, friends.size()):
		_fire_pattern(bullet_type, friends[i].global_position + Vector2(0, -28), Vector2.UP, "player")
	var sfx_key: String = SpaceBullet.bullet_info(bullet_type).sfx
	AudioBus.play_sfx(sfx_key, -12.0)

func _fire_pattern(bullet_type: String, origin: Vector2, direction: Vector2, team_name: String) -> void:
	match bullet_type:
		"BulletArrow":
			for angle in [-24.0, 0.0, 24.0]:
				_spawn_bullet(bullet_type, origin, direction.rotated(deg_to_rad(angle)), team_name)
		"Bullet3":
			for offset in [-24.0, 0.0, 24.0]:
				_spawn_bullet(bullet_type, origin + Vector2(offset, 0), direction, team_name)
		"BulletLaser":
			_spawn_bullet(bullet_type, origin + Vector2(0, -150), direction, team_name)
		_:
			_spawn_bullet(bullet_type, origin, direction, team_name)

func _spawn_bullet(type_name: String, origin: Vector2, direction: Vector2, team_name: String) -> void:
	var bullet := SpaceBullet.new()
	_spawn_parent().add_child(bullet)
	bullet.setup(type_name, team_name, origin, direction)

func _move(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse := get_global_mouse_position()
		if not mouse_drag and global_position.distance_to(mouse) < 80:
			mouse_drag = true
			drag_offset = global_position - mouse
		if mouse_drag:
			global_position = mouse + drag_offset
	else:
		mouse_drag = false
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	global_position += input * speed * delta
	global_position.x = clamp(global_position.x, 50.0, 1230.0)
	global_position.y = clamp(global_position.y, 90.0, 660.0)

func sync_friends() -> void:
	while friends.size() < GameData.friend_plane_count:
		var friend := Sprite2D.new()
		friend.texture = load("res://assets/sprites/friendplane.png")
		friend.scale = Vector2.ONE * 0.36
		_spawn_parent().add_child(friend)
		friends.append(friend)

func _update_friends(delta: float) -> void:
	sync_friends()
	for i in friends.size():
		friends[i].global_position = friends[i].global_position.lerp(global_position + friend_offsets[i], min(1.0, delta * 8.0))

func _on_died(_body: CombatBody) -> void:
	await get_tree().create_timer(0.8).timeout
	SceneFlow.go_game_over()

func _spawn_parent() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root
