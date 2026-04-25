extends Node2D

@export var lifetime := 1.0


func _ready() -> void:
	call_deferred("_start_particles")
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _start_particles() -> void:
	for child in get_children():
		if child is CPUParticles2D:
			var particles := child as CPUParticles2D
			particles.emitting = false
			particles.restart()
			particles.emitting = true
