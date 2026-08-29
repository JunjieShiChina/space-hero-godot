extends Node2D
class_name Stage4CanyonChunk

const DESIGN_WIDTH := 1920.0
const DESIGN_HEIGHT := 540.0

@onready var back_walls: Node2D = $BackWalls
@onready var wall_edges: Node2D = $WallEdges
@onready var midground_details: Node2D = $MidgroundDetails
@onready var hazard_layer: Node2D = $HazardLayer
@onready var foreground_layer: Node2D = $ForegroundLayer

var _definition: Dictionary = {}
var _corridor_left: PackedVector2Array = PackedVector2Array()
var _corridor_right: PackedVector2Array = PackedVector2Array()


func setup(definition: Dictionary) -> void:
	_definition = definition.duplicate(true)
	_rebuild()


func _process(_delta: float) -> void:
	pass


func _rebuild() -> void:
	_clear_generated(back_walls)
	_clear_generated(wall_edges)
	_clear_generated(midground_details)
	_clear_generated(hazard_layer)
	_clear_generated(foreground_layer)

	var geometry := _build_corridor_geometry()
	_corridor_left = geometry["left"]
	_corridor_right = geometry["right"]

	_create_wall_polygon(_left_wall_polygon(), Color(0.09, 0.08, 0.12, 0.94))
	_create_wall_polygon(_right_wall_polygon(), Color(0.08, 0.09, 0.13, 0.94))


func _build_corridor_geometry() -> Dictionary:
	var seed := int(_definition.get("seed", 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var center_top := float(_definition.get("center_top", 960.0))
	var center_bottom := float(_definition.get("center_bottom", 960.0))
	var width_top := float(_definition.get("width_top", 1040.0))
	var width_bottom := float(_definition.get("width_bottom", 1040.0))
	var jagged := float(_definition.get("jaggedness", 34.0))
	var sample_count := 6

	var left_points := PackedVector2Array()
	var right_points := PackedVector2Array()
	for i in range(sample_count):
		var t := float(i) / float(sample_count - 1)
		var y := lerpf(0.0, DESIGN_HEIGHT, t)
		var center_x := lerpf(center_top, center_bottom, t)
		var corridor_width := lerpf(width_top, width_bottom, t)
		var left_x := center_x - corridor_width * 0.5 + rng.randf_range(-jagged, jagged)
		var right_x := center_x + corridor_width * 0.5 + rng.randf_range(-jagged, jagged)
		left_x = clampf(left_x, 120.0, DESIGN_WIDTH * 0.5 - 180.0)
		right_x = clampf(right_x, DESIGN_WIDTH * 0.5 + 180.0, DESIGN_WIDTH - 120.0)
		if right_x - left_x < 420.0:
			var middle := (left_x + right_x) * 0.5
			left_x = middle - 210.0
			right_x = middle + 210.0
		left_points.append(Vector2(left_x, y))
		right_points.append(Vector2(right_x, y))
	return {
		"left": left_points,
		"right": right_points,
	}


func _left_wall_polygon() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	for point in _corridor_left:
		points.append(point)
	points.append(Vector2(0.0, DESIGN_HEIGHT))
	return points


func _right_wall_polygon() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(DESIGN_WIDTH, 0.0), Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)])
	for i in range(_corridor_right.size() - 1, -1, -1):
		points.append(_corridor_right[i])
	return points


func _create_wall_polygon(points: PackedVector2Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = _scale_polygon(points)
	polygon.color = color
	back_walls.add_child(polygon)


func _boundary_x_for_y(points: PackedVector2Array, y: float) -> float:
	if points.is_empty():
		return DESIGN_WIDTH * 0.5
	if y <= points[0].y:
		return points[0].x
	if y >= points[points.size() - 1].y:
		return points[points.size() - 1].x
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		if y >= a.y and y <= b.y:
			var t := inverse_lerp(a.y, b.y, y)
			return lerpf(a.x, b.x, t)
	return points[points.size() - 1].x


func _scale_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(DisplaySettings.to_current(point))
	return result


func _clear_generated(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
