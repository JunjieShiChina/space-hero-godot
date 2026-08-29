extends EnemyShip
class_name Stage4TakeoffEnemy

enum LaunchState {
	GROUNDED,
	TAKING_OFF,
	AIRBORNE,
}

const GROUND_SCALE_FACTOR := 0.34
const TAKEOFF_DURATION := 0.62
const GROUND_SCROLL_SPEED_DESIGN := 148.0
const AIR_SPEED_Y_DESIGN := 214.0
const AIR_SPEED_X_DESIGN := 188.0
const TAKEOFF_TRIGGER_Y_DESIGN := 214.0
const SHADOW_BASE_ALPHA := 0.34
const SHADOW_AIR_ALPHA := 0.08
const SHADOW_SCALE_X := 34.0
const SHADOW_SCALE_Y := 14.0

@onready var engine_trail: Node2D = $Sprite2D/EngineTrail
@onready var lift_dust: CPUParticles2D = $LiftDust
@onready var ground_shadow: Polygon2D = $GroundShadow
@onready var takeoff_ring: Line2D = $TakeoffRing

var _launch_state := LaunchState.GROUNDED
var _airborne_scale := Vector2.ONE
var _grounded_scale := Vector2.ONE
var _ground_scroll_speed := 0.0
var _air_speed_y := 0.0
var _air_speed_x := 0.0
var _takeoff_trigger_y := 0.0
var _takeoff_elapsed := 0.0
var _ring_base_width := 0.0
var _combat_collision_layer := 0
var _combat_collision_mask := 0
var _shadow_points := PackedVector2Array()
var _shadow_ground_scale := Vector2.ONE
var _shadow_air_scale := Vector2.ONE


func configure(_kind: String, pos: Vector2, target: PlayerShip) -> void:
	super.configure(_kind, pos, target)
	_airborne_scale = sprite.scale
	_grounded_scale = _airborne_scale * GROUND_SCALE_FACTOR
	sprite.scale = _grounded_scale
	rotation = PI
	can_shoot = false
	shoot_timer = 0.45
	_ground_scroll_speed = DisplaySettings.scale_value(GROUND_SCROLL_SPEED_DESIGN)
	_air_speed_y = DisplaySettings.scale_value(AIR_SPEED_Y_DESIGN)
	_air_speed_x = DisplaySettings.scale_value(AIR_SPEED_X_DESIGN)
	_takeoff_trigger_y = DisplaySettings.scale_value(TAKEOFF_TRIGGER_Y_DESIGN)
	_combat_collision_layer = collision_layer
	_combat_collision_mask = collision_mask
	_setup_shadow()
	_setup_takeoff_ring()
	_set_grounded_combat_state()


func take_damage(amount: float, hit_position := Vector2.ZERO, use_hit_position := false) -> void:
	if _launch_state != LaunchState.AIRBORNE:
		return
	super.take_damage(amount, hit_position, use_hit_position)


func _process(delta: float) -> void:
	match _launch_state:
		LaunchState.GROUNDED:
			_process_grounded(delta)
		LaunchState.TAKING_OFF:
			_process_taking_off(delta)
		LaunchState.AIRBORNE:
			_process_airborne(delta)

	if global_position.y > DisplaySettings.scale_value(1230.0):
		_retire()


func _process_grounded(delta: float) -> void:
	global_position.y += _ground_scroll_speed * delta
	if global_position.y >= _takeoff_trigger_y:
		_start_takeoff()


func _process_taking_off(delta: float) -> void:
	_takeoff_elapsed += delta
	var t := minf(_takeoff_elapsed / TAKEOFF_DURATION, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var overshoot_scale := _airborne_scale * 1.14
	sprite.scale = _grounded_scale.lerp(overshoot_scale, eased)
	global_position.y += lerpf(_ground_scroll_speed, DisplaySettings.scale_value(18.0), eased) * delta
	_update_takeoff_visuals(eased)
	if t >= 1.0:
		_finish_takeoff()


func _process_airborne(delta: float) -> void:
	_update_airborne_velocity()
	global_position += velocity * delta
	rotation = PI + clampf(velocity.x / DisplaySettings.scale_value(960.0), -0.24, 0.24)
	if can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			_shoot()


func _start_takeoff() -> void:
	_launch_state = LaunchState.TAKING_OFF
	_takeoff_elapsed = 0.0
	engine_trail.visible = true
	lift_dust.restart()
	lift_dust.emitting = true
	takeoff_ring.visible = true
	takeoff_ring.modulate = Color(0.36, 0.96, 1.0, 0.82)
	AudioBus.play_sfx("meteor", -16.0)


func _finish_takeoff() -> void:
	_launch_state = LaunchState.AIRBORNE
	sprite.scale = _airborne_scale
	ground_shadow.scale = _shadow_air_scale
	ground_shadow.modulate.a = SHADOW_AIR_ALPHA
	takeoff_ring.visible = false
	can_shoot = true
	shoot_timer = 0.18
	velocity = Vector2(0.0, _air_speed_y)
	collision_layer = _combat_collision_layer
	collision_mask = _combat_collision_mask
	monitoring = true
	monitorable = true
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = false

	var settle_tween := create_tween()
	settle_tween.tween_property(sprite, "scale", _airborne_scale, 0.12)


func _update_airborne_velocity() -> void:
	var target_x := DisplaySettings.logical_center().x
	if player != null and not player.dead:
		target_x = player.global_position.x
	var delta_x := target_x - global_position.x
	velocity.x = clampf(delta_x * 1.8, -_air_speed_x, _air_speed_x)
	velocity.y = _air_speed_y


func _set_grounded_combat_state() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = true
	engine_trail.visible = false
	lift_dust.emitting = false
	takeoff_ring.visible = false


func _setup_shadow() -> void:
	_shadow_points = _ellipse_points(
		DisplaySettings.scale_value(SHADOW_SCALE_X),
		DisplaySettings.scale_value(SHADOW_SCALE_Y),
		18
	)
	ground_shadow.polygon = _shadow_points
	ground_shadow.color = Color(0.03, 0.04, 0.08, SHADOW_BASE_ALPHA)
	_shadow_ground_scale = Vector2.ONE
	_shadow_air_scale = Vector2(0.56, 0.56)
	ground_shadow.scale = _shadow_ground_scale


func _setup_takeoff_ring() -> void:
	var radius := DisplaySettings.scale_value(22.0)
	var points := _ellipse_points(radius, radius * 0.5, 22)
	if not points.is_empty():
		points.append(points[0])
	takeoff_ring.points = points
	_ring_base_width = DisplaySettings.scale_value(5.0)
	takeoff_ring.width = _ring_base_width


func _update_takeoff_visuals(progress: float) -> void:
	ground_shadow.scale = _shadow_ground_scale.lerp(_shadow_air_scale, progress)
	ground_shadow.modulate.a = lerpf(SHADOW_BASE_ALPHA, SHADOW_AIR_ALPHA, progress)
	takeoff_ring.scale = Vector2.ONE * lerpf(0.72, 2.2, progress)
	takeoff_ring.width = lerpf(_ring_base_width, 0.0, progress)
	takeoff_ring.modulate.a = lerpf(0.82, 0.0, progress)


func _ellipse_points(radius_x: float, radius_y: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(point_count):
		var angle := TAU * float(i) / float(point_count)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
