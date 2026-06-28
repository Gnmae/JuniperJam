# best to use UIDs in here to avoid files moving or being renamed being an issue

extends Node
const SCENE_PATHS: Dictionary = {
	"decoration_target": "uid://dqvk10pyet8q3",
	"order_ticket": "uid://65qph7dmwyaf",
	"cake_base_selection": "uid://bw4krn5w0jakp",
	"top_decoration": "uid://dmsc35y2hrm1a",
	"cake_base_option": "uid://bkc4bjmjqe25g",
	"spin_speed": "uid://bp6bmverypc85",
	"opening_scene": "uid://cyo7hmcnjxr4o",
	"hub": "uid://fg43ldteyxa3",
	"main_menu": "uid://b2vxniec67375"
}

const DECORATION_SCENES: Dictionary = {
	"top_decoration": "uid://ba1jiq1ndvwhj",
	"side_decoration": "uid://ctwmi3l0qgbal",
	"candle": "res://scenes/decorations/candle.tscn",
	"frosting_dollop": "uid://cqxgshefb05yh"
}
const FROSTING_COLORS: Array[Dictionary] = [
	{"id": "red", "label": "Red", "color": Color(0.94, 0.13, 0.15)},
	{"id": "orange", "label": "Orange", "color": Color(1.00, 0.50, 0.05)},
	{"id": "yellow", "label": "Yellow", "color": Color(0.99, 0.90, 0.08)},
	{"id": "green", "label": "Green", "color": Color(0.13, 0.75, 0.22)},
	{"id": "blue", "label": "Blue", "color": Color(0.10, 0.46, 0.98)},
	{"id": "indigo", "label": "Indigo", "color": Color(0.24, 0.13, 0.72)},
	{"id": "violet", "label": "Violet", "color": Color(0.60, 0.10, 0.85)},
]
const ORDERS: Dictionary = {
	"order_01": "uid://1wc2u0di81mg"
}

const CAKE_BASES: Array[Dictionary] = [
	{
		"id": "yellow_sponge",
		"name": "Yellow Sponge",
		"texture": preload("uid://bm26e8phsmuyd"),
		"color": Color(1.0, 0.95, 0.7)
	},
	{
		"id": "chocolate",
		"name": "Chocolate",
		"texture": preload("uid://bm26e8phsmuyd"),
		"color": Color(0.337, 0.204, 0.137, 1.0)
	},
	{
		"id": "red_velvet",
		"name": "Red Velvet",
		"texture": preload("uid://bm26e8phsmuyd"),
		"color": Color(0.85, 0.25, 0.3)
	},
	{
		"id": "vanilla",
		"name": "Vanilla",
		"texture": preload("uid://bm26e8phsmuyd"),
		"color": Color(1.0, 0.98, 0.9)
	},
	{
		"id": "lemon",
		"name": "Lemon",
		"texture": preload("uid://bm26e8phsmuyd"),
		"color": Color(1.0, 0.967, 0.0, 1.0)
	}
]

# todo, side and top decoration dictionaries could just be combined some way
const TOP_DECORATIONS: Array[Dictionary] = [
	{
		"id": "candle",
		"label": "Candle",
		"atlas_pos": Vector2(0, 0),
		"collision_radius": 12.0,
		"scale": Vector2.ONE,
	},
	{
		"id": "cherry",
		"label": "Cherry",
		"atlas_pos": Vector2(1, 0),
		"collision_radius": 10.0,
		"scale": Vector2.ONE,
	},
]

const SIDE_DECORATIONS: Array[Dictionary] = [
	{
		"id": "candle",
		"label": "Candle",
		"atlas_pos": Vector2(0, 0),
		"collision_radius": 12.0,
		"scale": Vector2.ONE,
	},
	{
		"id": "cherry",
		"label": "Cherry",
		"atlas_pos": Vector2(1, 0),
		"collision_radius": 10.0,
		"scale": Vector2.ONE,
	},
]

#decoration tools so far
# todo, add frosting subtool controls e.g. color? shape? size?
const TOOLS: Array[Dictionary] = [
	{
		"id": "frosting",
		"label": "Frosting",
		"type": "frosting",
		"pointer_atlas_pos": Vector2(0, 0),
	},
	{
		"id": "candle",
		"label": "Candle",
		"type": "decoration",
		"pointer_atlas_pos": Vector2(1, 0),
	},
	{
		"id": "cherry",
		"label": "Cherry",
		"type": "decoration",
		"pointer_atlas_pos": Vector2(2, 0),
	},
]
