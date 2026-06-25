class_name SessionResult
extends Resource

var order: Order = null
var base_correct: bool = false
var spin_bonus: float = 0.0
var spin_speed: float = 0.0
var frosting_accuracy: float = 0.0
var decoration_score: float = 0.0
var time_remaining: float = 0.0
var total_score: float = 0.0

# decorations placed by player
var top_decorations_placed: Array[DecorationPlacement] = []
var side_decorations_placed: Array[DecorationPlacement] = []

var side_frosting_accuracy: float = 0.0
