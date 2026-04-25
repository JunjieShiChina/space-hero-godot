extends Node

signal changed

const STAGE_PATHS := [
	"res://scenes/stage_1.tscn",
	"res://scenes/stage_2.tscn",
	"res://scenes/stage_3.tscn",
]

var coin_count := 0
var current_stage_index := 0
var player_health := 200.0
var max_health := 200.0
var bullet_slots := ["EMPTY", "EMPTY", "EMPTY"]
var current_bullet_index := 0
var friend_plane_count := 0
var friend_plane_limit := 2
var stats := {}

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	coin_count = 0
	current_stage_index = 0
	player_health = max_health
	bullet_slots = ["EMPTY", "EMPTY", "EMPTY"]
	current_bullet_index = 0
	friend_plane_count = 0
	stats = {
		"meteor": 0,
		"ship": 0,
		"ep2": 0,
		"rotation_ep": 0,
		"meteor_enemy": 0,
		"small_boss": 0,
		"boss1": 0,
		"boss2": 0,
		"boss3": 0,
		"coin1": 0,
		"coin2": 0,
		"coin3": 0,
	}
	changed.emit()

func add_coins(amount: int) -> void:
	coin_count = max(0, coin_count + amount)
	changed.emit()

func spend_coins(amount: int) -> bool:
	if coin_count < amount:
		return false
	add_coins(-amount)
	return true

func record_stat(key: String) -> void:
	if not stats.has(key):
		stats[key] = 0
	stats[key] += 1
	changed.emit()

func current_bullet() -> String:
	var bullet: String = bullet_slots[current_bullet_index]
	return "Bullet1" if bullet == "EMPTY" else bullet

func switch_bullet() -> void:
	current_bullet_index = (current_bullet_index + 1) % bullet_slots.size()
	changed.emit()

func equip_bullet(bullet_type: String) -> void:
	current_bullet_index = (current_bullet_index + 1) % bullet_slots.size()
	bullet_slots[current_bullet_index] = bullet_type
	changed.emit()

func buy_friend() -> bool:
	if friend_plane_count >= friend_plane_limit:
		return false
	friend_plane_count += 1
	changed.emit()
	return true

func stage_path() -> String:
	return STAGE_PATHS[current_stage_index]

func has_next_stage() -> bool:
	return current_stage_index + 1 < STAGE_PATHS.size()

func advance_stage_index() -> void:
	current_stage_index += 1
	changed.emit()
