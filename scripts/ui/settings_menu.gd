extends Node2D

signal closed(reason: String)

const MENU_FONT_TEXTURE := preload("res://assets/sprites/duat font corporal.png")
const TITLE_BASE_Y := 474.0
const MODE_BASE_Y := 588.0
const RESOLUTION_BASE_Y := 678.0
const BACK_BASE_Y := 768.0
const MENU_GLYPH_SPACING := 8.0
const MENU_ITEM_BASE_SCALE := 1.08
const TITLE_BASE_SCALE := 1.26
const SELECTOR_BASE_SCALE := 1.38
const SELECTOR_OFFSET := Vector2(-70.5, 28.5)
const MENU_GLYPHS := {
	"0": Rect2(457, 427, 44, 51),
	"1": Rect2(43, 427, 22, 51),
	"2": Rect2(69, 427, 45, 51),
	"8": Rect2(359, 427, 45, 51),
	"A": Rect2(30, 212, 45, 52),
	"B": Rect2(80, 212, 45, 52),
	"C": Rect2(129, 212, 45, 52),
	"D": Rect2(177, 212, 45, 52),
	"E": Rect2(227, 212, 45, 52),
	"F": Rect2(274, 212, 45, 52),
	"G": Rect2(323, 212, 45, 52),
	"I": Rect2(421, 212, 45, 52),
	"K": Rect2(30, 278, 45, 52),
	"M": Rect2(134, 278, 45, 52),
	"N": Rect2(187, 278, 45, 52),
	"O": Rect2(236, 278, 45, 52),
	"Q": Rect2(333, 278, 45, 59),
	"R": Rect2(381, 278, 45, 52),
	"S": Rect2(432, 278, 45, 52),
	"T": Rect2(478, 278, 45, 52),
	"U": Rect2(30, 344, 45, 52),
	"W": Rect2(132, 344, 45, 52),
	"X": Rect2(184, 344, 45, 52),
	"Z": Rect2(283, 344, 45, 52),
}

@onready var title_item: Node2D = $Title
@onready var mode_item: Node2D = $Mode
@onready var resolution_item: Node2D = $Resolution
@onready var back_item: Node2D = $Back
@onready var selector: Sprite2D = $Selector
@onready var items: Array[Node2D] = [$Mode, $Resolution, $Back]

var selected := 0
var active := false


func _ready() -> void:
	hide()
	_refresh_labels()
	_update_selection()
	if not DisplaySettings.changed.is_connected(_on_display_settings_changed):
		DisplaySettings.changed.connect(_on_display_settings_changed)


func is_open() -> bool:
	return active


func open(initial_selected := 0) -> void:
	active = true
	selected = clampi(initial_selected, 0, items.size() - 1)
	show()
	_refresh_labels()
	_update_selection()


func close(reason := "back") -> void:
	if not active:
		return
	active = false
	hide()
	closed.emit(reason)


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("move_up"):
		selected = max(0, selected - 1)
		AudioBus.play_sfx("select")
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		selected = min(items.size() - 1, selected + 1)
		AudioBus.play_sfx("select")
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		_adjust_selected(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_adjust_selected(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if selected == 2:
			close("back")
		else:
			_adjust_selected(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close("back")
		get_viewport().set_input_as_handled()


func _adjust_selected(step: int) -> void:
	match selected:
		0:
			DisplaySettings.cycle_display_mode(step)
		1:
			DisplaySettings.cycle_resolution(step)
		_:
			return
	AudioBus.play_sfx("select")
	_refresh_labels()
	_update_selection()


func _on_display_settings_changed() -> void:
	_refresh_labels()
	_update_selection()


func _refresh_labels() -> void:
	var scale_value := DisplaySettings.scale_factor()
	var center_x := DisplaySettings.logical_center().x
	selector.scale = Vector2.ONE * SELECTOR_BASE_SCALE * scale_value
	var title_width := _set_atlas_text(title_item, "SETTINGS", TITLE_BASE_SCALE * scale_value)
	title_item.position = Vector2(center_x - title_width * 0.5, TITLE_BASE_Y * scale_value)

	var mode_width := _set_atlas_text(
		mode_item,
		"MODE %s" % DisplaySettings.current_display_mode_label(),
		MENU_ITEM_BASE_SCALE * scale_value
	)
	mode_item.position = Vector2(center_x - mode_width * 0.5, MODE_BASE_Y * scale_value)

	var resolution_width := _set_atlas_text(
		resolution_item,
		"SIZE %s" % DisplaySettings.current_label(),
		MENU_ITEM_BASE_SCALE * scale_value
	)
	resolution_item.position = Vector2(
		center_x - resolution_width * 0.5,
		RESOLUTION_BASE_Y * scale_value
	)

	var back_width := _set_atlas_text(back_item, "BACK", MENU_ITEM_BASE_SCALE * scale_value)
	back_item.position = Vector2(center_x - back_width * 0.5, BACK_BASE_Y * scale_value)


func _update_selection() -> void:
	if not active:
		return
	var item_position := items[selected].position
	selector.position = item_position + SELECTOR_OFFSET * DisplaySettings.scale_factor()


func _set_atlas_text(parent: Node2D, text_value: String, scale_value := MENU_ITEM_BASE_SCALE) -> float:
	for child in parent.get_children():
		child.queue_free()
	var cursor := 0.0
	var spacing := MENU_GLYPH_SPACING * (scale_value / MENU_ITEM_BASE_SCALE)
	for index in text_value.length():
		var character := text_value.substr(index, 1)
		var region: Rect2 = MENU_GLYPHS.get(character, Rect2())
		if region.size == Vector2.ZERO:
			cursor += 36.0 * (scale_value / MENU_ITEM_BASE_SCALE)
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = MENU_FONT_TEXTURE
		atlas.region = region
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.position = Vector2(cursor, 0)
		sprite.scale = Vector2.ONE * scale_value
		parent.add_child(sprite)
		cursor += region.size.x * scale_value + spacing
	return maxf(0.0, cursor - spacing)
