extends Node2D
class_name DamageNumber

const PixelNumberScene := preload("res://scenes/ui/pixel_number_display.tscn")

@export var lifetime := 1.15

var amount := 1
var _spawn_global_position := Vector2.ZERO
var _has_spawn_global_position := false


func setup(value: float, spawn_global_position := Vector2.ZERO, has_spawn_global_position := false) -> void:
	amount = maxi(1, int(ceil(value)))
	_spawn_global_position = spawn_global_position
	_has_spawn_global_position = has_spawn_global_position


func _ready() -> void:
	if _has_spawn_global_position:
		global_position = _spawn_global_position
	z_index = 120
	var display := PixelNumberScene.instantiate() as PixelNumberDisplay
	add_child(display)
	display.set_number(amount)
	display.scale = Vector2.ONE * 0.36 * DisplaySettings.scale_factor()
	display.modulate = Color(1.0, 0.86, 0.22, 1.0)
	display.position = Vector2(-display.content_width * display.scale.x * 0.5, 0.0)

	var start := position
	var end := start + DisplaySettings.to_current(Vector2(randf_range(-2.0, 2.0), randf_range(-8.0, -5.0)))
	scale = Vector2.ONE * 0.72
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", end, lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.92, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.84, lifetime - 0.12).set_delay(0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.78).set_delay(0.32)
	tween.chain().tween_callback(queue_free)
