extends Node

signal changed

const STAGE_PATHS := [
	"res://scenes/stage_1.tscn",
	"res://scenes/stage_2.tscn",
	"res://scenes/stage_3.tscn",
]
const MAX_WEAPON_LEVEL := 10
const DAMAGE_BONUS_PER_LEVEL := 0.10
const FIRE_RATE_STEP := 0.05
const MISSILE_FIRE_RATE_STEP := 0.10
const MISSILE_PARALLEL_FIRE_RATE_LEVEL_STEP := 5

var coin_count := 0
var current_stage_index := 0
var player_health := 200.0
var max_health := 200.0
var shield_health := 0.0
var shield_max_health := 100.0
var bullet_slots := ["EMPTY", "EMPTY", "EMPTY"]
var current_bullet_index := 0
var friend_plane_count := 0
var friend_plane_limit := 2
var weapon_levels := {}
var weapon_fire_rate_steps := {}
var stats := {}

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	coin_count = 0
	current_stage_index = 0
	player_health = max_health
	shield_health = 0.0
	shield_max_health = 100.0
	bullet_slots = ["EMPTY", "EMPTY", "EMPTY"]
	current_bullet_index = 0
	friend_plane_count = 0
	weapon_levels = {"Bullet1": 1}
	weapon_fire_rate_steps = {"Bullet1": 0}
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
	return _normalized_bullet_type(bullet)

func switch_bullet() -> void:
	current_bullet_index = (current_bullet_index + 1) % bullet_slots.size()
	changed.emit()

func equip_bullet(bullet_type: String) -> bool:
	var normalized := _normalized_bullet_type(bullet_type)
	if normalized == "":
		return false
	_ensure_weapon_state(normalized)
	var existing_index := bullet_slots.find(normalized)
	if existing_index >= 0:
		current_bullet_index = existing_index
		var current_level := int(weapon_levels[normalized])
		if current_level >= MAX_WEAPON_LEVEL:
			changed.emit()
			return false
		weapon_levels[normalized] = current_level + 1
	else:
		current_bullet_index = (current_bullet_index + 1) % bullet_slots.size()
		bullet_slots[current_bullet_index] = normalized
	changed.emit()
	return true

func add_fire_rate_to_current_bullet() -> bool:
	var bullet_type := current_bullet()
	_ensure_weapon_state(bullet_type)
	weapon_fire_rate_steps[bullet_type] = int(weapon_fire_rate_steps[bullet_type]) + 1
	changed.emit()
	return true

func weapon_level(bullet_type: String) -> int:
	var normalized := _normalized_bullet_type(bullet_type)
	_ensure_weapon_state(normalized)
	return int(weapon_levels[normalized])

func current_weapon_level() -> int:
	return weapon_level(current_bullet())

func weapon_damage_multiplier(bullet_type: String) -> float:
	var level := weapon_level(bullet_type)
	return 1.0 + float(maxi(0, level - 1)) * DAMAGE_BONUS_PER_LEVEL

func weapon_fire_rate_multiplier(bullet_type: String) -> float:
	var normalized := _normalized_bullet_type(bullet_type)
	_ensure_weapon_state(normalized)
	return 1.0 + float(weapon_fire_rate_steps[normalized]) * weapon_fire_rate_step_value(normalized)

func current_fire_rate_multiplier() -> float:
	return weapon_fire_rate_multiplier(current_bullet())

func weapon_fire_rate_step_value(bullet_type: String) -> float:
	return MISSILE_FIRE_RATE_STEP if _normalized_bullet_type(bullet_type) == "BulletMissile" else FIRE_RATE_STEP

func weapon_fire_rate_level(bullet_type: String) -> int:
	var normalized := _normalized_bullet_type(bullet_type)
	_ensure_weapon_state(normalized)
	return int(weapon_fire_rate_steps[normalized]) + 1

func current_fire_rate_level() -> int:
	return weapon_fire_rate_level(current_bullet())

func missile_parallel_count() -> int:
	_ensure_weapon_state("BulletMissile")
	return 1 + int(float(weapon_fire_rate_steps["BulletMissile"]) / float(MISSILE_PARALLEL_FIRE_RATE_LEVEL_STEP))

func set_shield(value: float, max_value: float) -> void:
	shield_max_health = maxf(1.0, max_value)
	shield_health = clampf(value, 0.0, shield_max_health)
	changed.emit()

func clear_shield() -> void:
	if shield_health <= 0.0:
		return
	shield_health = 0.0
	changed.emit()

func shield_ratio() -> float:
	if shield_max_health <= 0.0:
		return 0.0
	return clampf(shield_health / shield_max_health, 0.0, 1.0)

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

func _ensure_weapon_state(bullet_type: String) -> void:
	var normalized := _normalized_bullet_type(bullet_type)
	if normalized == "":
		return
	if not weapon_levels.has(normalized):
		weapon_levels[normalized] = 1
	if not weapon_fire_rate_steps.has(normalized):
		weapon_fire_rate_steps[normalized] = 0

func _normalized_bullet_type(bullet_type: String) -> String:
	if bullet_type == "" or bullet_type == "EMPTY":
		return "Bullet1"
	return bullet_type
