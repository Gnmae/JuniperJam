extends Control

var current_order: Order = null
var session_result: SessionResult = null
var cake_base_id: String = ""
var cake_base_data: Dictionary = {}

func start_order(order: Order) -> void:
	current_order = order
	session_result = SessionResult.new()
	session_result.order = order
const SAVE_PATH = "user://save_game.dat"

const DEFAULT_SAVE_DATA: Dictionary = {
	"flags": [],
	"last_3_orders": [],
	"total_orders_completed": 0,
	"total_score": 0,
	"high_score": 0
}

var save_data: Dictionary = DEFAULT_SAVE_DATA.duplicate()

func complete_order(order_id: String, score: int) -> void:
	save_data["total_orders_completed"] += 1
	save_data["total_score"] += score

	if score > save_data["high_score"]:
		save_data["high_score"] = score

	var order_record = {
		"order_id": order_id,
		"score": score,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_data["last_3_orders"].append(order_record)
	if save_data["last_3_orders"].size() > 3:
		save_data["last_3_orders"].pop_front()

	save_to_file(JSON.stringify(save_data))

func get_last_orders() -> Array:
	return save_data["last_3_orders"]

func get_total_orders() -> int:
	return save_data["total_orders_completed"]

func get_total_score() -> int:
	return save_data["total_score"]

func get_high_score() -> int:
	return save_data["high_score"]
func save_to_file(content: String) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(content)

func load_from_file() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	return file.get_as_text()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func new_game() -> void:
	delete_save()
	save_data = {
		"flags": [],
		"last_3_orders": [],
		"total_orders_completed": 0,
		"total_score": 0,
		"high_score": 0
	}
	current_order = null
	session_result = null
	cake_base_id = ""
	cake_base_data = {}

func set_flag(flag: String) -> void:
	if not save_data["flags"].has(flag):
		save_data["flags"].append(flag)
	save_to_file(JSON.stringify(save_data))

func has_flag(flag: String) -> bool:
	return save_data["flags"].has(flag)

func load_save() -> void:
	var content = load_from_file()
	if content:
		var parsed = JSON.parse_string(content)
		if parsed:
			save_data = DEFAULT_SAVE_DATA.duplicate()
			save_data.merge(parsed, true)
