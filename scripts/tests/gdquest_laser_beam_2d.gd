@tool
extends RayCast2D

@export var cast_speed := 7000.0
@export var max_length := 1400.0
@export var start_distance := 40.0
@export var growth_time := 0.1
@export var color := Color(1.31836, 0.609067, 1.5, 1.0): set = set_color
@export var is_casting := false: set = set_is_casting

var tween: Tween = null

@onready var line_2d: Line2D = %Line2D
@onready var casting_particles: GPUParticles2D = %CastingParticles2D
@onready var collision_particles: GPUParticles2D = %CollisionParticles2D
@onready var beam_particles: GPUParticles2D = %BeamParticles2D

@onready var line_width := line_2d.width


func _ready() -> void:
	_setup_visuals()
	line_2d.points[0] = Vector2.RIGHT * start_distance
	line_2d.points[1] = Vector2.ZERO
	line_2d.visible = false
	casting_particles.position = line_2d.points[0]
	set_color(color)
	set_is_casting(is_casting)

	if not Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

	var laser_end_position := target_position
	force_raycast_update()

	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = laser_end_position

	line_2d.points[1] = laser_end_position

	var laser_start_position := line_2d.points[0]
	beam_particles.position = laser_start_position + (laser_end_position - laser_start_position) * 0.5
	var material := beam_particles.process_material as ParticleProcessMaterial
	if material:
		material.emission_box_extents.x = laser_end_position.distance_to(laser_start_position) * 0.5

	collision_particles.emitting = is_colliding()


func set_is_casting(new_value: bool) -> void:
	if is_casting == new_value:
		return
	is_casting = new_value
	set_physics_process(is_casting)

	if beam_particles == null:
		return

	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting

	if is_casting:
		var laser_start := Vector2.RIGHT * start_distance
		line_2d.points[0] = laser_start
		line_2d.points[1] = laser_start
		casting_particles.position = laser_start
		appear()
	else:
		target_position = Vector2.ZERO
		collision_particles.emitting = false
		disappear()


func appear() -> void:
	line_2d.visible = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)


func disappear() -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
	tween.tween_callback(line_2d.hide)


func set_color(new_color: Color) -> void:
	color = new_color

	if line_2d == null:
		return

	line_2d.modulate = new_color
	casting_particles.modulate = new_color
	collision_particles.modulate = new_color
	beam_particles.modulate = new_color


func _setup_visuals() -> void:
	line_2d.width = 16.0
	line_2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_2d.end_cap_mode = Line2D.LINE_CAP_ROUND
	line_2d.joint_mode = Line2D.LINE_JOINT_ROUND
	line_2d.antialiased = true

	var circle_texture := _make_glowing_circle_texture()

	casting_particles.texture = circle_texture
	casting_particles.process_material = _make_casting_particle_material()
	casting_particles.lifetime = 0.3
	casting_particles.emitting = false
	casting_particles.show_behind_parent = true
	casting_particles.visibility_rect = Rect2(0.0, -18.722, 29.6756, 38.4841)

	beam_particles.texture = circle_texture
	beam_particles.process_material = _make_beam_particle_material()
	beam_particles.amount = 50
	beam_particles.preprocess = 1.0
	beam_particles.randomness = 1.0
	beam_particles.emitting = false
	beam_particles.visibility_rect = Rect2(-2500.0, -2500.0, 5000.0, 5000.0)

	collision_particles.texture = circle_texture
	collision_particles.process_material = _make_collision_particle_material()
	collision_particles.amount = 16
	collision_particles.lifetime = 0.3
	collision_particles.emitting = false
	collision_particles.show_behind_parent = true
	collision_particles.visibility_rect = Rect2(-2500.0, -2500.0, 5000.0, 5000.0)


func _make_glowing_circle_texture() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(31.5, 31.5)
	for y in range(64):
		for x in range(64):
			var distance := Vector2(x, y).distance_to(center) / 31.5
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = pow(alpha, 2.6)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_casting_particle_material() -> ParticleProcessMaterial:
	var curve := Curve.new()
	curve.add_point(Vector2(0.518072, 1.0), 0.0, -3.53434)
	curve.add_point(Vector2(1.0, 0.0))
	var curve_texture := CurveTexture.new()
	curve_texture.width = 2048
	curve_texture.curve = curve

	var material := ParticleProcessMaterial.new()
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.5
	material.scale_max = 0.5
	material.scale_curve = curve_texture
	material.color_ramp = _make_alpha_ramp([0.582915, 1.0], [1.0, 0.0])
	return material


func _make_beam_particle_material() -> ParticleProcessMaterial:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.503614, 0.957505))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_texture := CurveTexture.new()
	curve_texture.curve = curve

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(680.0, 20.0, 1.0)
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 0.0
	material.gravity = Vector3.ZERO
	material.tangential_accel_min = 100.0
	material.tangential_accel_max = 100.0
	material.scale_min = 0.3
	material.scale_max = 0.3
	material.scale_curve = curve_texture
	material.color_ramp = _make_alpha_ramp([0.0, 0.719557, 1.0], [1.0, 1.0, 0.0])
	return material


func _make_collision_particle_material() -> ParticleProcessMaterial:
	var curve := Curve.new()
	curve.add_point(Vector2(0.518072, 1.0), 0.0, -3.53434)
	curve.add_point(Vector2(1.0, 0.0))
	var curve_texture := CurveTexture.new()
	curve_texture.width = 2048
	curve_texture.curve = curve

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.spread = 50.0
	material.initial_velocity_min = 300.0
	material.initial_velocity_max = 300.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.5
	material.scale_max = 0.5
	material.scale_curve = curve_texture
	material.color_ramp = _make_alpha_ramp([0.582915, 1.0], [1.0, 0.0])
	return material


func _make_alpha_ramp(offsets: Array[float], alphas: Array[float]) -> GradientTexture1D:
	var gradient := Gradient.new()
	for index in range(offsets.size()):
		gradient.add_point(offsets[index], Color(1.0, 1.0, 1.0, alphas[index]))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 256
	return texture
