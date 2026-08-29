extends Node2D

const MOVE_SPEED := 520.0

var _laser_enabled := true

@onready var _ship: Node2D = $PlayerShip
@onready var _laser: RayCast2D = $PlayerShip/GDQuestLaserBeam2D
@onready var _status_label: Label = $CanvasLayer/Instructions/VBoxContainer/Status


func _ready() -> void:
	_update_status()


func _process(delta: float) -> void:
	_ship.look_at(get_global_mouse_position())
	_laser.set("is_casting", _laser_enabled)
	_update_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U:
			_laser_enabled = not _laser_enabled
			_update_status()
		elif event.keycode == KEY_R:
			_ship.global_position = Vector2(540.0, 620.0)
			_ship.rotation = 0.0


func _update_movement(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_ship.position += direction * MOVE_SPEED * delta
	_ship.position.x = clampf(_ship.position.x, 180.0, 820.0)
	_ship.position.y = clampf(_ship.position.y, 180.0, 900.0)


func _update_status() -> void:
	if _status_label == null:
		return
	_status_label.text = "Laser: %s" % ("ON" if _laser_enabled else "OFF")
