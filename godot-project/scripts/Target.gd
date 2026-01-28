extends Node2D

signal hit(points: int)

@export var start_size: float = 64.0
@export var shrink_rate: float = 18.0 # pixels per second
@export var points: int = 10

var current_size: float
var hit_area := CircleShape2D.new()

func _ready():
	current_size = start_size
	# Add a simple circle Visual (ColorRect-like via CanvasItem)
	var sprite = ColorRect.new()
	sprite.color = Color8(255,100,80)
	sprite.anchor_left = 0.5
	sprite.anchor_top = 0.5
	sprite.rect_size = Vector2(current_size, current_size)
	add_child(sprite)
	# Collision detection helper: we'll detect clicks by checking point distance
	set_process(true)

func _process(delta):
	current_size = max(6.0, current_size - shrink_rate * delta)
	# Update visual size if present
	for c in get_children():
		if c is ColorRect:
			c.rect_size = Vector2(current_size, current_size)
	# If target is too small, consider it missed and remove (and damage player)
	if current_size <= 7.0:
		queue_free()
		# Damage player by sending a global signal via Main (Main handles removing health on miss when player shoots)
		# Alternatively, Main penalizes on shots; here we simply remove

# Called by Main when clicked
func is_point_inside(point: Vector2) -> bool:
	# local space check
	var dist = global_position.distance_to(point)
	return dist <= current_size * 0.5

func hit():
	# award points
	# Emit a custom signal for Main to pick up
	if get_parent() and get_parent().has_method("_on_target_hit"):
		get_parent()._on_target_hit(points)
	queue_free()