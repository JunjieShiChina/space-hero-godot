extends Node2D
class_name ShopDropManager

@export var item_scene: PackedScene
@export var drop_interval := 15.0
@export var drop_speed := 576.0
@export var unity_x_min := -4.0
@export var unity_x_max := 4.0
@export var spawn_y := -192.0

var stage: Node
var timer := 0.0


func _ready() -> void:
	if item_scene == null:
		item_scene = preload("res://scenes/entities/shop_item.tscn")


func _process(delta: float) -> void:
	timer += delta
	if timer >= drop_interval:
		timer = 0.0
		drop()


func drop() -> Node:
	var definition := _pick_definition()
	if definition == null:
		return null
	var scene := definition.get("item_scene") as PackedScene
	if scene == null:
		scene = item_scene
	if scene == null:
		return null
	var item := scene.instantiate()
	if item == null:
		return null
	_spawn_parent().add_child(item)
	var design_x := 960.0 + randf_range(unity_x_min, unity_x_max) * 192.0
	var design_pos := Vector2(design_x, spawn_y)
	if item.has_method("configure_from_definition"):
		item.configure_from_definition(definition, DisplaySettings.to_current(design_pos), drop_speed, stage)
	return item


func _pick_definition() -> Node:
	var definitions: Array[Node] = []
	var total_weight := 0.0
	for child in get_children():
		var child_weight := float(child.get("weight"))
		if child_weight > 0.0:
			definitions.append(child)
			total_weight += child_weight
	if definitions.is_empty():
		return null

	var roll := randf() * total_weight
	var cursor := 0.0
	for definition in definitions:
		cursor += float(definition.get("weight"))
		if roll <= cursor:
			return definition
	return definitions.back()


func _spawn_parent() -> Node:
	return stage if stage else get_parent()
