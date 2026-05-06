extends Node

signal changed

const DESIGN_SIZE := Vector2i(1920, 1080)
const MIN_SIZE := Vector2i(960, 540)
const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const CONFIG_KEY := "resolution_index"
const MODE_CONFIG_KEY := "display_mode"
const RESOLUTIONS := [
	{"label": "1080P", "size": Vector2i(1920, 1080)},
	{"label": "2K", "size": Vector2i(2560, 1440)},
]
const DISPLAY_MODES := [
	{"label": "WINDOW", "mode": DisplayServer.WINDOW_MODE_WINDOWED},
	{"label": "MAX", "mode": DisplayServer.WINDOW_MODE_MAXIMIZED},
	{"label": "FULL", "mode": DisplayServer.WINDOW_MODE_FULLSCREEN},
]

var current_index := 0
var has_saved_resolution := false
var current_display_mode := 0


func _ready() -> void:
	_load()
	_configure_window_scale()
	_apply_display_mode()
	_apply_window_constraints()
	if has_saved_resolution and _is_plain_windowed():
		_apply_windowed_size()


func current_label() -> String:
	return RESOLUTIONS[current_index]["label"]


func current_size() -> Vector2i:
	return RESOLUTIONS[current_index]["size"]


func current_display_mode_label() -> String:
	return DISPLAY_MODES[current_display_mode]["label"]


func logical_size() -> Vector2:
	return Vector2(current_size())


func logical_center() -> Vector2:
	return logical_size() * 0.5


func scale_factor() -> float:
	return float(current_size().x) / float(DESIGN_SIZE.x)


func scale_value(value: float) -> float:
	return value * scale_factor()


func scale_font_size(size_value: int) -> int:
	return maxi(1, int(round(float(size_value) * scale_factor())))


func to_current(design_position: Vector2) -> Vector2:
	return design_position * scale_factor()


func toggle_resolution() -> void:
	cycle_resolution(1)


func toggle_display_mode() -> void:
	cycle_display_mode(1)


func cycle_resolution(step: int) -> void:
	set_resolution(current_index + step)


func cycle_display_mode(step: int) -> void:
	set_display_mode(current_display_mode + step)


func set_resolution(index: int) -> void:
	current_index = posmod(index, RESOLUTIONS.size())
	has_saved_resolution = true
	_configure_window_scale()
	_apply_window_constraints()
	if _is_plain_windowed():
		_apply_windowed_size()
	_save()
	changed.emit()


func set_display_mode(index: int) -> void:
	current_display_mode = posmod(index, DISPLAY_MODES.size())
	_apply_display_mode()
	_apply_window_constraints()
	if _is_plain_windowed() and has_saved_resolution:
		_apply_windowed_size()
	_save()
	changed.emit()


func _configure_window_scale() -> void:
	var window := get_window()
	if window == null:
		return
	var target_size := current_size()
	if window.content_scale_size != target_size:
		window.content_scale_size = target_size
	if window.content_scale_mode != Window.CONTENT_SCALE_MODE_VIEWPORT:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	if window.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if window.content_scale_stretch != Window.CONTENT_SCALE_STRETCH_FRACTIONAL:
		window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _apply_display_mode() -> void:
	var mode := int(DISPLAY_MODES[current_display_mode]["mode"])
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _apply_window_constraints() -> void:
	var window := get_window()
	if window == null or window.is_embedded():
		return
	if _is_plain_windowed():
		if window.min_size != MIN_SIZE:
			window.min_size = MIN_SIZE
		if window.borderless:
			window.borderless = false
	else:
		if window.min_size != Vector2i.ZERO:
			window.min_size = Vector2i.ZERO


func _apply_windowed_size() -> void:
	var window := get_window()
	if window == null or window.is_embedded():
		return
	window.size = current_size()


func _is_plain_windowed() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED


func _load() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		return
	current_index = clampi(int(cfg.get_value(CONFIG_SECTION, CONFIG_KEY, 0)), 0, RESOLUTIONS.size() - 1)
	current_display_mode = clampi(int(cfg.get_value(CONFIG_SECTION, MODE_CONFIG_KEY, 0)), 0, DISPLAY_MODES.size() - 1)
	has_saved_resolution = true


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CONFIG_SECTION, CONFIG_KEY, current_index)
	cfg.set_value(CONFIG_SECTION, MODE_CONFIG_KEY, current_display_mode)
	cfg.save(CONFIG_PATH)
