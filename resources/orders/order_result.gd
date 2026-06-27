class_name SessionResult
extends Resource

var order: Order = null
var base_correct: bool = false
var spin_bonus: float = 0.0
var spin_speed: float = 0.0
var top_frosting_accuracy: float = 0.0
var top_decoration_accuracy: float = 0.0
var time_remaining: float = 0.0
var side_frosting_accuracy: float = 0.0
var side_decoration_accuracy: float = 0.0

var top_final_score: int = 0

# total score used just before the order results hsown in the hub
var total_score: int = 0

# decorations placed by player
var top_decorations_placed: Array[DecorationPlacement] = []
var side_decorations_placed: Array[DecorationPlacement] = []
