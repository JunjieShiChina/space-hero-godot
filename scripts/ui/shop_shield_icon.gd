extends Node2D

@export var pulse_speed := 2.6

@onready var shield_field: ColorRect = get_node_or_null("ShieldField") as ColorRect
@onready var icon_particles: GPUParticles2D = get_node_or_null("IconParticles") as GPUParticles2D

var _time := 0.0
var _shader_material: ShaderMaterial
var _particle_texture: Texture2D


func _ready() -> void:
	if shield_field and shield_field.material is ShaderMaterial:
		_shader_material = (shield_field.material as ShaderMaterial).duplicate() as ShaderMaterial
		shield_field.material = _shader_material
	_configure_particles()


func _process(delta: float) -> void:
	_time += delta
	var pulse := (sin(_time * pulse_speed) + 1.0) * 0.5
	scale = Vector2.ONE * (1.0 + pulse * 0.035)
	if _shader_material:
		_shader_material.set_shader_parameter("pulse_boost", pulse)


func _configure_particles() -> void:
	if icon_particles == null:
		return
	icon_particles.texture = _make_particle_texture()
	icon_particles.amount = 34
	icon_particles.lifetime = 1.05
	icon_particles.preprocess = 1.05
	icon_particles.randomness = 0.76
	icon_particles.fixed_fps = 30
	icon_particles.visibility_rect = Rect2(Vector2(-46, -46), Vector2(92, 92))
	icon_particles.material = _additive_material()
	icon_particles.process_material = _make_particle_material()
	icon_particles.emitting = true


func _make_particle_material() -> ParticleProcessMaterial:
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 28.0
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = 4.0
	particle_material.initial_velocity_max = 28.0
	particle_material.scale_min = 0.32
	particle_material.scale_max = 0.72
	particle_material.angular_velocity_min = -85.0
	particle_material.angular_velocity_max = 85.0
	particle_material.color = Color(1.0, 0.78, 0.10, 0.16)
	particle_material.color_ramp = _make_particle_ramp()
	particle_material.particle_flag_disable_z = true
	return particle_material


func _make_particle_ramp() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.58, 0.02, 0.0))
	gradient.set_color(1, Color(1.0, 0.62, 0.02, 0.0))
	gradient.add_point(0.18, Color(1.0, 0.97, 0.34, 0.24))
	gradient.add_point(0.52, Color(1.0, 0.76, 0.08, 0.15))
	gradient.add_point(0.82, Color(1.0, 0.96, 0.34, 0.10))
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _make_particle_texture() -> Texture2D:
	if _particle_texture:
		return _particle_texture
	var image := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	var center := Vector2(2.0, 2.0)
	for y in 5:
		for x in 5:
			var distance := Vector2(float(x), float(y)).distance_to(center)
			var alpha := clampf(1.0 - distance / 2.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_particle_texture = ImageTexture.create_from_image(image)
	return _particle_texture


func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material
