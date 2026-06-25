# best to use UIDs in here to avoid files moving or being renamed being an issue

extends Node
const SCENE_PATHS: Dictionary = {
	"decoration_target": "uid://dqvk10pyet8q3",
	"order_ticket": "uid://65qph7dmwyaf",
	"cake_base_selection": "uid://bw4krn5w0jakp",
	"top_decotation": "uid://cxqdlgqpte2sp",
	"cake_base_option" : "uid://bkc4bjmjqe25g",
	"spin_speed" : "uid://bp6bmverypc85",
	"opening_scene" : "uid://cyo7hmcnjxr4o",
	"hub" : "uid://fg43ldteyxa3",
	"main_menu" : "uid://b2vxniec67375"
}

const DECORATION_SCENES: Dictionary = {
	"candle": "res://scenes/decorations/candle.tscn",
	"frosting_dollop" : "uid://cqxgshefb05yh"
}

const ORDERS: Dictionary = {
	"order_01": "res://orders/order_01.tres",
	"order_02": "uid://0jwq38lq0vk2",
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
