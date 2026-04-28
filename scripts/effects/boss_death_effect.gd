extends Node2D

@export var lifetime := 3.65

const BURSTS := [
	{"delay": 0.00, "offset": Vector2(0, 0), "scale": 1.35, "heavy": true},
	{"delay": 0.14, "offset": Vector2(-72, -18), "scale": 0.92, "heavy": false},
	{"delay": 0.30, "offset": Vector2(68, 20), "scale": 0.98, "heavy": false},
	{"delay": 0.52, "offset": Vector2(-30, 58), "scale": 0.82, "heavy": false},
	{"delay": 0.78, "offset": Vector2(42, -58), "scale": 0.86, "heavy": false},
	{"delay": 1.06, "offset": Vector2(-86, 38), "scale": 0.78, "heavy": false},
	{"delay": 1.34, "offset": Vector2(88, -8), "scale": 0.76, "heavy": false},
	{"delay": 1.68, "offset": Vector2(-18, -72), "scale": 0.72, "heavy": false},
	{"delay": 2.04, "offset": Vector2(18, 72), "scale": 0.68, "heavy": false},
	{"delay": 2.42, "offset": Vector2(0, 0), "scale": 1.02, "heavy": true},
]
const PARTICLE_TEMPLATES := ["CoreBurst", "RadialSparks", "SmokePuffs", "HeavySmoke", "DebrisStreaks", "EmberRain"]

@onready var core_flash_template: Polygon2D = $CoreFlash
@onready var shock_ring_template: Line2D = $ShockRing
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	_hide_templates()
	AudioBus.play_sfx("boss_explosion_long", -7.0)
	_play_camera_kick(14.0)
	call_deferred("_play_bursts")


func _hide_templates() -> void:
	if animation_player:
		animation_player.stop()
	if core_flash_template:
		core_flash_template.visible = false
	if shock_ring_template:
		shock_ring_template.visible = false
	for template_name in PARTICLE_TEMPLATES:
		var particles := get_node_or_null(template_name) as CPUParticles2D
		if particles:
			particles.emitting = false
			particles.visible = false


func _play_bursts() -> void:
	var elapsed := 0.0
	for burst in BURSTS:
		var delay := float(burst["delay"]) - elapsed
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return
		elapsed = float(burst["delay"])
		_spawn_burst(burst["offset"] as Vector2, float(burst["scale"]))
		_play_burst_sfx(bool(burst.get("heavy", false)))
		_play_camera_kick(7.0 * float(burst["scale"]))
	await get_tree().create_timer(maxf(0.1, lifetime - elapsed)).timeout
	if is_inside_tree():
		queue_free()


func _spawn_burst(design_offset: Vector2, burst_scale: float) -> void:
	var offset := DisplaySettings.to_current(design_offset)
	_spawn_flash(offset, burst_scale)
	_spawn_ring(offset, burst_scale)
	for template_name in PARTICLE_TEMPLATES:
		_spawn_particles(template_name, offset, burst_scale)


func _play_burst_sfx(heavy: bool) -> void:
	if heavy:
		AudioBus.play_sfx("boss_explosion", -2.0)
	else:
		AudioBus.play_sfx("explosion", -8.0)


func _spawn_flash(offset: Vector2, burst_scale: float) -> void:
	if core_flash_template == null:
		return
	var flash := core_flash_template.duplicate() as Polygon2D
	add_child(flash)
	flash.visible = true
	flash.position = offset
	flash.scale = Vector2.ONE * 0.22 * burst_scale
	flash.modulate = Color(1.0, 0.92, 0.34, 0.96)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2.ONE * 1.35 * burst_scale, 0.09)
	tween.parallel().tween_property(flash, "modulate", Color(1.0, 0.42, 0.05, 0.7), 0.09)
	tween.tween_property(flash, "scale", Vector2.ONE * 2.15 * burst_scale, 0.28)
	tween.parallel().tween_property(flash, "modulate", Color(1.0, 0.04, 0.0, 0.0), 0.28)
	tween.tween_callback(flash.queue_free)


func _spawn_ring(offset: Vector2, burst_scale: float) -> void:
	if shock_ring_template == null:
		return
	var ring := shock_ring_template.duplicate() as Line2D
	add_child(ring)
	ring.visible = true
	ring.position = offset
	ring.scale = Vector2.ONE * 0.28 * burst_scale
	ring.modulate = Color(1.0, 0.72, 0.08, 0.72)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * 1.95 * burst_scale, 0.36)
	tween.parallel().tween_property(ring, "modulate", Color(1.0, 0.1, 0.0, 0.0), 0.36)
	tween.tween_callback(ring.queue_free)


func _spawn_particles(template_name: String, offset: Vector2, burst_scale: float) -> void:
	var template := get_node_or_null(template_name) as CPUParticles2D
	if template == null:
		return
	var particles := template.duplicate() as CPUParticles2D
	add_child(particles)
	particles.visible = true
	particles.position = offset
	particles.scale = Vector2.ONE * burst_scale
	particles.emitting = false
	particles.restart()
	particles.emitting = true
	var cleanup_delay := particles.lifetime + 0.22
	get_tree().create_timer(cleanup_delay).timeout.connect(particles.queue_free)


func _play_camera_kick(amplitude: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var original_offset := camera.offset
	var kick := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * DisplaySettings.scale_value(amplitude)
	var tween := create_tween()
	tween.tween_property(camera, "offset", original_offset + kick, 0.025)
	tween.tween_property(camera, "offset", original_offset, 0.08)
