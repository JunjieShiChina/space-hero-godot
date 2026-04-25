extends Node2D
class_name PixelNumberDisplay

const FONT_TEXTURE := preload("res://assets/sprites/duat font corporal.png")
const DIGIT_REGIONS := {
	"0": Rect2(1073, 743, 45, 52),
	"1": Rect2(660, 743, 22, 52),
	"2": Rect2(686, 743, 45, 52),
	"3": Rect2(733, 743, 45, 52),
	"4": Rect2(782, 743, 45, 52),
	"5": Rect2(829, 743, 45, 52),
	"6": Rect2(879, 743, 45, 52),
	"7": Rect2(928, 743, 45, 52),
	"8": Rect2(976, 743, 45, 52),
	"9": Rect2(1025, 743, 44, 52),
}
const SLASH_WIDTH := 28.0
const SLASH_HEIGHT := 52.0
const SLASH_COLOR := Color(1.0, 0.48, 0.16)
const SLASH_HIGHLIGHT := Color(1.0, 0.73, 0.35)
const SLASH_SHADOW := Color(0.25, 0.06, 0.22)

@export var digit_spacing := 3.0
@export var digit_scale := 1.0
@export var text := ""

var content_width := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if text == "":
		set_number(0)
	else:
		set_text(text)


func set_number(value: int) -> void:
	set_text(str(maxi(0, value)))


func set_text(value: String) -> void:
	text = value
	for child in get_children():
		child.free()

	var cursor := 0.0
	for index in value.length():
		var character := value.substr(index, 1)
		if character == "/":
			_add_slash(cursor)
			cursor += SLASH_WIDTH * digit_scale + digit_spacing
			continue
		if not DIGIT_REGIONS.has(character):
			cursor += 24.0 * digit_scale + digit_spacing
			continue
		var region: Rect2 = DIGIT_REGIONS[character]
		var atlas := AtlasTexture.new()
		atlas.atlas = FONT_TEXTURE
		atlas.region = region
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(cursor, 0.0)
		sprite.scale = Vector2.ONE * digit_scale
		add_child(sprite)
		cursor += region.size.x * digit_scale + digit_spacing

	content_width = maxf(0.0, cursor - digit_spacing)


func _add_slash(cursor: float) -> void:
	var slash := Node2D.new()
	slash.position = Vector2(cursor, 0.0)
	slash.scale = Vector2.ONE * digit_scale
	add_child(slash)

	var shadow := Line2D.new()
	shadow.points = PackedVector2Array([Vector2(7, SLASH_HEIGHT - 3), Vector2(SLASH_WIDTH - 4, 6)])
	shadow.width = 7.0
	shadow.default_color = SLASH_SHADOW
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.add_child(shadow)

	var body := Line2D.new()
	body.points = PackedVector2Array([Vector2(4, SLASH_HEIGHT - 6), Vector2(SLASH_WIDTH - 8, 4)])
	body.width = 7.0
	body.default_color = SLASH_COLOR
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.add_child(body)

	var highlight := Line2D.new()
	highlight.points = PackedVector2Array([Vector2(6, SLASH_HEIGHT - 8), Vector2(SLASH_WIDTH - 9, 7)])
	highlight.width = 2.0
	highlight.default_color = SLASH_HIGHLIGHT
	highlight.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.add_child(highlight)
