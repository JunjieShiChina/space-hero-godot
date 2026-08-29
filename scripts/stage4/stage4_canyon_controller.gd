extends Node2D
class_name Stage4CanyonController

const CHUNK_SCENE := preload("res://scenes/stage4/stage4_canyon_chunk.tscn")
const CHUNK_HEIGHT_DESIGN := 540.0
const SCROLL_SPEED_DESIGN := 154.0
const CHUNK_DEFINITIONS := [
	{
		"name": "wide_intro",
		"seed": 401,
		"center_top": 960.0,
		"center_bottom": 930.0,
		"width_top": 1180.0,
		"width_bottom": 1080.0,
		"jaggedness": 24.0,
	},
	{
		"name": "left_squeeze",
		"seed": 402,
		"center_top": 1110.0,
		"center_bottom": 1030.0,
		"width_top": 880.0,
		"width_bottom": 760.0,
		"jaggedness": 28.0,
	},
	{
		"name": "wide_relief",
		"seed": 404,
		"center_top": 920.0,
		"center_bottom": 970.0,
		"width_top": 1200.0,
		"width_bottom": 1160.0,
		"jaggedness": 20.0,
	},
	{
		"name": "right_squeeze",
		"seed": 406,
		"center_top": 820.0,
		"center_bottom": 900.0,
		"width_top": 820.0,
		"width_bottom": 740.0,
		"jaggedness": 28.0,
	},
	{
		"name": "center_choke",
		"seed": 407,
		"center_top": 960.0,
		"center_bottom": 960.0,
		"width_top": 760.0,
		"width_bottom": 840.0,
		"jaggedness": 32.0,
	},
	{
		"name": "beam_gate",
		"seed": 403,
		"center_top": 970.0,
		"center_bottom": 970.0,
		"width_top": 980.0,
		"width_bottom": 940.0,
		"jaggedness": 26.0,
		"extra_hazards": [
			{
				"type": "beam_pair",
				"x_positions": [792.0, 1128.0],
				"top": 96.0,
				"bottom": 446.0,
				"width": 42.0,
			},
		],
	},
	{
		"name": "pillar",
		"seed": 405,
		"center_top": 960.0,
		"center_bottom": 990.0,
		"width_top": 980.0,
		"width_bottom": 920.0,
		"jaggedness": 26.0,
		"extra_hazards": [
			{
				"type": "pillar",
				"position": Vector2(1010.0, 268.0),
				"radius": 98.0,
				"rotation": 0.46,
			},
		],
	},
	{
		"name": "double_beam",
		"seed": 408,
		"center_top": 970.0,
		"center_bottom": 930.0,
		"width_top": 1030.0,
		"width_bottom": 900.0,
		"jaggedness": 24.0,
		"extra_hazards": [
			{
				"type": "beam_pair",
				"x_positions": [720.0, 1200.0],
				"top": 84.0,
				"bottom": 414.0,
				"width": 36.0,
			},
			{
				"type": "pillar",
				"position": Vector2(962.0, 404.0),
				"radius": 76.0,
				"rotation": -0.32,
			},
		],
	},
]

var _chunks: Array = []
var _definition_index := 0


func _ready() -> void:
	_rebuild_chunks()
	if not DisplaySettings.changed.is_connected(_on_display_changed):
		DisplaySettings.changed.connect(_on_display_changed)


func _process(delta: float) -> void:
	if _chunks.is_empty():
		return
	var speed := DisplaySettings.scale_value(SCROLL_SPEED_DESIGN)
	for chunk in _chunks:
		chunk.position.y += speed * delta
	var bottom_limit := DisplaySettings.logical_size().y + _chunk_height()
	for chunk in _chunks:
		if chunk.position.y >= bottom_limit:
			_recycle_chunk(chunk)


func _on_display_changed() -> void:
	_rebuild_chunks()


func _rebuild_chunks() -> void:
	for chunk in _chunks:
		if chunk != null:
			chunk.queue_free()
	_chunks.clear()
	_definition_index = 0

	var chunk_count := int(ceil(DisplaySettings.logical_size().y / _chunk_height())) + 3
	var start_y := -_chunk_height() * float(chunk_count - 2)
	for i in range(chunk_count):
		var chunk := CHUNK_SCENE.instantiate() as Node2D
		add_child(chunk)
		chunk.position = Vector2(0.0, start_y + _chunk_height() * float(i))
		chunk.setup(_next_definition())
		_chunks.append(chunk)


func _recycle_chunk(chunk: Node2D) -> void:
	var top_y := INF
	for candidate in _chunks:
		if candidate == chunk:
			continue
		top_y = minf(top_y, candidate.position.y)
	chunk.position.y = top_y - _chunk_height()
	chunk.setup(_next_definition())


func _next_definition() -> Dictionary:
	var definition: Dictionary = CHUNK_DEFINITIONS[_definition_index % CHUNK_DEFINITIONS.size()]
	_definition_index += 1
	return definition


func _chunk_height() -> float:
	return DisplaySettings.scale_value(CHUNK_HEIGHT_DESIGN)
