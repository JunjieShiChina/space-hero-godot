extends Node

signal changed

const DESIGN_SIZE := Vector2i(1920, 1080)
const MIN_SIZE := Vector2i(960, 540)
const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const CONFIG_KEY := "resolution_index"
const RESOLUTIONS := [
	{"label": "1080P", "size": Vector2i(1920, 1080)},
	{"label": "2K", "size": Vector2i(2560, 1440)},
]

var current_index := 0
var has_saved_resolution := false


func _ready() -> void:
	_load()
	var window := get_window()
	if window and not window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.connect(_on_window_size_changed)
	_configure_window_scale()
	if has_saved_resolution and _is_plain_windowed():
		_apply_current()


func current_label() -> String:
	return RESOLUTIONS[current_index]["label"]


func current_size() -> Vector2i:
	return RESOLUTIONS[current_index]["size"]


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
	set_resolution(current_index + 1)


func set_resolution(index: int) -> void:
	current_index = posmod(index, RESOLUTIONS.size())
	has_saved_resolution = true
	_apply_current()
	_save()
	changed.emit()


func _configure_window_scale() -> void:
	var window := get_window()
	if window == null:
		return
	window.content_scale_size = current_size()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.min_size = MIN_SIZE


func _apply_current() -> void:
	var window := get_window()
	if window == null:
		return
	if _can_resize_window(window):
		window.size = current_size()
	_configure_window_scale()


func _is_plain_windowed() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED


func _can_resize_window(window: Window) -> bool:
	return _is_plain_windowed() and not window.is_embedded()


func _on_window_size_changed() -> void:
	_configure_window_scale()


func _load() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		return
	current_index = clampi(int(cfg.get_value(CONFIG_SECTION, CONFIG_KEY, 0)), 0, RESOLUTIONS.size() - 1)
	has_saved_resolution = true


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CONFIG_SECTION, CONFIG_KEY, current_index)
	cfg.save(CONFIG_PATH)
