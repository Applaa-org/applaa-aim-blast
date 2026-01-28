extends Node2D

const TARGET_SCENE: PackedScene = preload("res://scenes/Target.tscn")
const SPAWN_MARGIN: int = 80
const MAX_TARGETS: int = 4
const SPAWN_INTERVAL: float = 0.9
const TARGET_SCORE_GOAL: int = 200

@onready var hud := $CanvasLayer/HUD
@onready var score_label := $CanvasLayer/HUD/ScoreLabel
@onready var high_label := $CanvasLayer/HUD/HighScoreLabel
@onready var accuracy_label := $CanvasLayer/HUD/AccuracyLabel
@onready var health_label := $CanvasLayer/HUD/HealthLabel
@onready var crosshair := $CanvasLayer/HUD/Crosshair
@onready var world := $World

var spawn_timer := 0.0
var hits: int = 0
var shots: int = 0
var health: int = 3

func _ready():
	# Initialize HUD high score to 0 immediately
	score_label.text = "Score: 0"
	high_label.text = "Best: 0"
	accuracy_label.text = "Accuracy: 0%"
	health_label.text = "Health: %d" % health
	# Listen to Global changes
	Global.connect("score_changed", Callable(self, "_on_score_changed"))
	Global.connect("high_score_changed", Callable(self, "_on_global_high_changed"))
	# Pre-fill with Global.high_score if loaded (Global will emit)
	high_label.text = "Best: %d" % Global.high_score
	# Cursor: hide system cursor and use crosshair sprite
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Initial spawn
	_spawn_target()
	# Make sure HUD visible
	hud.visible = true

func _process(delta):
	# crosshair follows mouse
	var pos = get_viewport().get_mouse_position()
	crosshair.position = pos
	# For mobile touches: show crosshair at last touch too (handled in input)
	# Spawning logic
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = SPAWN_INTERVAL
		if world.get_child_count() < MAX_TARGETS:
			_spawn_target()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shots += 1
		_handle_shot(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		shots += 1
		# Touch position
		_handle_shot(event.position)

func _handle_shot(position: Vector2):
	# Check overlapping targets manually
	var hit_any := false
	for child in world.get_children():
		if child is Node2D and child.has_method("is_point_inside") and child.is_point_inside(position):
			hit_any = true
			child.hit()
			break
	if not hit_any:
		# Miss: lose 1 health
		health -= 1
		health_label.text = "Health: %d" % health
		if health <= 0:
			_game_over(false)

func _spawn_target():
	var t = TARGET_SCENE.instantiate()
	# Random position inside viewport with margin
	var vp = get_viewport_rect().size
	var x = randi() % int(vp.x - SPAWN_MARGIN*2) + SPAWN_MARGIN
	var y = randi() % int(vp.y - SPAWN_MARGIN*2) + SPAWN_MARGIN
	t.position = Vector2(x, y)
	world.add_child(t)

func _on_target_hit(points: int):
	hits += 1
	Global.add_score(points)
	shots = shots # keep shots (accuracy recalculated below)
	score_label.text = "Score: %d" % Global.score
	_update_accuracy()
	if Global.score >= TARGET_SCORE_GOAL:
		_game_over(true)

func _on_score_changed(new_score):
	score_label.text = "Score: %d" % new_score

func _on_global_high_changed(new_high):
	high_label.text = "Best: %d" % new_high

func _update_accuracy():
	var acc = 0
	if shots > 0:
		acc = int(float(hits) / float(shots) * 100.0)
	accuracy_label.text = "Accuracy: %d%%" % acc

func _game_over(victory: bool):
	# Save score using Global.save
	# Provide player name
	var name = Global.player_name if Global.player_name != "" else "Player"
	Global.save_score_to_storage(name, Global.score)
	# Navigate to Victory or Defeat
	if victory:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/DefeatScreen.tscn")