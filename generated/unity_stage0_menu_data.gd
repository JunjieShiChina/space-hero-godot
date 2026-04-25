extends RefCounted

const FONT_PATH := "res://assets/sprites/duat font corporal.png"
const BACKGROUND_PATH := "res://assets/sprites/Background_01.png"
const STARS_PATH := "res://assets/sprites/Stars.png"
const SELECTOR_PATH := "res://assets/sprites/Spaceship_Enemy - SingleShot.png"
const HERO_PATH := "res://assets/sprites/Spaceship_Protagonist - P1.png"
const FRIEND_PATH := "res://assets/sprites/friendplane.png"

const TITLE_LETTERS := [
	{"x": 0.0000, "rect": Rect2(1049.0, 278.0, 44.0, 52.0), "size": Vector2(0.4400, 0.5200)},
	{"x": 0.9300, "rect": Rect2(901.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 1.8600, "rect": Rect2(647.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 2.8100, "rect": Rect2(746.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 3.7400, "rect": Rect2(844.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 5.2800, "rect": Rect2(989.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 6.1900, "rect": Rect2(844.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 7.1100, "rect": Rect2(998.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 8.0600, "rect": Rect2(879.0, 0.0, 88.0, 101.0), "size": Vector2(0.8800, 1.0100)},
]

const NEW_GAME_LETTERS := [
	{"x": 0.0000, "rect": Rect2(187.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 0.5200, "rect": Rect2(227.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 0.9900, "rect": Rect2(132.0, 344.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 1.8200, "rect": Rect2(323.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 2.2400, "rect": Rect2(30.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 2.6900, "rect": Rect2(134.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 3.1600, "rect": Rect2(227.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
]

const QUIT_GAME_LETTERS := [
	{"x": 0.0000, "rect": Rect2(333.0, 278.0, 45.0, 59.0), "size": Vector2(0.4500, 0.5900)},
	{"x": 0.4200, "rect": Rect2(30.0, 344.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 0.8300, "rect": Rect2(421.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 1.2300, "rect": Rect2(478.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 1.8100, "rect": Rect2(323.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 2.2300, "rect": Rect2(30.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 2.7000, "rect": Rect2(134.0, 278.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
	{"x": 3.1500, "rect": Rect2(227.0, 212.0, 45.0, 52.0), "size": Vector2(0.4500, 0.5200)},
]

const ORBIT_RADIUS_UNITS := 0.500
const ORBIT_SPEED_UNITS := 5.000
const FRIEND_START_ANGLES := [60.000, 0.000]
