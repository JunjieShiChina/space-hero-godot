extends Node2D

@export var x_radius := 66.0
@export var y_radius := 88.0
@export var orbit_speed := 2.0

@onready var hero_ship: Sprite2D = $HeroShip
@onready var wingmen: Array[Sprite2D] = [
	$Wingman1,
	$Wingman2,
]

var orbit_angle := 0.0


func _ready() -> void:
	_update_wingmen()


func _process(delta: float) -> void:
	orbit_angle -= delta * orbit_speed
	_update_wingmen()


func _update_wingmen() -> void:
	for index in wingmen.size():
		var angle := orbit_angle + float(index) * TAU / float(wingmen.size())
		wingmen[index].position = hero_ship.position + Vector2(cos(angle) * x_radius, sin(angle) * y_radius)
		wingmen[index].rotation = 0.0
