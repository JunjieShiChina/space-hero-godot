extends CanvasLayer

signal transition_started(path: String)
signal transition_midpoint(path: String)
signal transition_finished(path: String)

@export var fade_out_seconds := 0.32
@export var hold_seconds := 0.08
@export var fade_in_seconds := 0.38

@onready var fade_rect: ColorRect = $FadeRect

var _active_tween: Tween
var _current_alpha := 0.0
var _is_transitioning := false
var _active_path := ""
var _queued_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	_set_alpha(0.0)
	fade_rect.visible = false
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(path: String) -> void:
	if _is_transitioning:
		if path == _active_path or path == _queued_path:
			return
		_queued_path = path
		return

	_is_transitioning = true
	_active_path = path
	transition_started.emit(path)
	fade_rect.visible = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_to(1.0, fade_out_seconds, Tween.EASE_IN_OUT)
	transition_midpoint.emit(path)

	var tree := get_tree()
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("Unable to change scene to %s: %s" % [path, error_string(err)])
	else:
		await tree.scene_changed
		if hold_seconds > 0.0:
			await tree.create_timer(hold_seconds, true, false, true).timeout

	await _fade_to(0.0, fade_in_seconds, Tween.EASE_IN_OUT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.visible = false
	_is_transitioning = false
	_active_path = ""
	transition_finished.emit(path)

	if not _queued_path.is_empty():
		var next_path := _queued_path
		_queued_path = ""
		change_scene(next_path)


func is_transitioning() -> bool:
	return _is_transitioning


func _fade_to(alpha: float, duration: float, ease_type: Tween.EaseType) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_method(_set_alpha, _current_alpha, alpha, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(ease_type)
	await _active_tween.finished


func _set_alpha(alpha: float) -> void:
	_current_alpha = clampf(alpha, 0.0, 1.0)
	var rect_color := fade_rect.color
	rect_color.a = _current_alpha
	fade_rect.color = rect_color
