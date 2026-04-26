extends Node
class_name ShopDropDefinition

@export_enum("friend", "bullet", "shield") var product_type := "bullet"
@export var bullet_type := ""
@export var price := 0
@export var icon_texture: Texture2D
@export var icon_region := Rect2()
@export var icon_scale := 1.0
@export var item_scale := 1.0
@export var item_scene: PackedScene
@export var weight := 1.0
