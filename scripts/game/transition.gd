extends Control

const FONT_TEXTURE := preload("res://assets/sprites/duat font corporal.png")
const WAIT_SECONDS := 3.0
const TEXT_BASE_SCALE := 1.28
const TEXT_BASE_Y := 432.0
const GLYPH_SPACING := 6.0
const WORD_SPACING := 34.0
const START_COLOR := Color(0.993, 1.0, 0.042, 1.0)
const END_COLOR := Color(0.991, 0.634, 0.051, 1.0)
const GLYPHS := {
	"S": Rect2(1049, 595, 44, 51),
	"T": Rect2(1095, 595, 45, 51),
	"A": Rect2(647, 529, 45, 52),
	"G": Rect2(940, 529, 45, 52),
	"E": Rect2(844, 529, 45, 52),
	"1": Rect2(660, 743, 22, 52),
	"2": Rect2(686, 743, 45, 52),
	"3": Rect2(733, 743, 45, 52),
}

@onready var stage_text: Node2D = $StageText

var anim_time := 0.0


func _ready() -> void:
	_render_stage_text()
	await _wait_for_screen_transition()
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(WAIT_SECONDS).timeout
	if not is_inside_tree():
		return
	SceneFlow.continue_after_transition()


func _process(delta: float) -> void:
	anim_time += delta
	var pulse := (sin(anim_time * PI * 2.0) + 1.0) * 0.5
	stage_text.modulate = START_COLOR.lerp(END_COLOR, pulse)


func _render_stage_text() -> void:
	for child in stage_text.get_children():
		child.free()
	var text_value := "STAGE %d" % (GameData.current_stage_index + 1)
	var scale_value := TEXT_BASE_SCALE * DisplaySettings.scale_factor()
	var text_width := _measure_text(text_value, scale_value)
	var cursor := 0.0
	stage_text.position = Vector2((DisplaySettings.logical_size().x - text_width) * 0.5, DisplaySettings.scale_value(TEXT_BASE_Y))
	stage_text.scale = Vector2.ONE * scale_value
	stage_text.modulate = START_COLOR
	for index in text_value.length():
		var character := text_value.substr(index, 1)
		if character == " ":
			cursor += WORD_SPACING
			continue
		var region: Rect2 = GLYPHS.get(character, Rect2())
		if region.size == Vector2.ZERO:
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = FONT_TEXTURE
		atlas.region = region
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.position = Vector2(cursor, 0.0)
		stage_text.add_child(sprite)
		cursor += region.size.x + GLYPH_SPACING


func _measure_text(text_value: String, scale_value: float) -> float:
	var width := 0.0
	for index in text_value.length():
		var character := text_value.substr(index, 1)
		if character == " ":
			width += WORD_SPACING
			continue
		var region: Rect2 = GLYPHS.get(character, Rect2())
		if region.size != Vector2.ZERO:
			width += region.size.x + GLYPH_SPACING
	return max(0.0, width - GLYPH_SPACING) * scale_value


func _wait_for_screen_transition() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	while is_inside_tree():
		var transition_layer := tree.root.get_node_or_null("ScreenTransition")
		if not transition_layer or not transition_layer.has_method("is_transitioning") or not transition_layer.call("is_transitioning"):
			return
		await tree.process_frame
