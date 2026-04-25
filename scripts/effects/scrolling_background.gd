extends TextureRect
class_name ScrollingBackground

const SCROLL_SHADER := preload("res://shaders/scrolling_background.gdshader")

@export var scroll_texture: Texture2D
@export var scroll_speed := 0.035
@export var scroll_axis := Vector2(0.0, -1.0)
@export var tint := Color.WHITE

var _scroll_offset := 0.0
var _shader_material: ShaderMaterial
var _last_view_size := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	if scroll_texture:
		texture = scroll_texture
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SCROLL_SHADER
	material = _shader_material
	_sync_shader_values()


func configure(background_texture: Texture2D, speed: float) -> void:
	scroll_texture = background_texture
	scroll_speed = speed
	texture = background_texture
	_sync_shader_values()


func _process(delta: float) -> void:
	_scroll_offset = fposmod(_scroll_offset + scroll_speed * delta, 1.0)
	if _shader_material:
		_shader_material.set_shader_parameter("scroll_offset", _scroll_offset)
	var view_size := _view_size()
	if not view_size.is_equal_approx(_last_view_size):
		_sync_shader_values()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_shader_values()


func _sync_shader_values() -> void:
	if _shader_material == null:
		return
	var view_size := _view_size()
	_last_view_size = view_size
	_shader_material.set_shader_parameter("viewport_size", view_size)
	_shader_material.set_shader_parameter("texture_size_px", _texture_size())
	_shader_material.set_shader_parameter("scroll_axis", scroll_axis)
	_shader_material.set_shader_parameter("tint", tint)
	_shader_material.set_shader_parameter("scroll_offset", _scroll_offset)


func _view_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		return viewport_size
	return DisplaySettings.logical_size()


func _texture_size() -> Vector2:
	if texture:
		return texture.get_size()
	return Vector2.ONE
