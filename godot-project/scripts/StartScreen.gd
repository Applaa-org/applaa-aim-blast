extends Control

@onready var start_button := $CenterPanel/VBox/StartButton
@onready var close_button := $CenterPanel/VBox/CloseButton
@onready var name_input := $CenterPanel/VBox/NameInput
@onready var high_label := $TopBar/HighScoreLabel
@onready var leaderboard := $CenterPanel/VBox/Leaderboard

func _ready():
	# Initialize high score display to 0 immediately (MANDATORY)
	high_label.text = "High Score: 0"
	high_label.visible = true
	# Pre-fill name from Global if present
	if Global.player_name != "":
		name_input.text = Global.player_name
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	close_button.pressed.connect(_on_close_pressed)
	# Listen to Global high score updates
	Global.connect("high_score_changed", Callable(self, "_on_high_score_changed"))
	# Request load (Global handles JS bridging)
	Global._load_game_data()

func _on_start_pressed():
	# Save entered name locally, then start game
	Global.player_name = name_input.text.strip()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_close_pressed():
	get_tree().quit()

func _on_high_score_changed(new_high):
	high_label.text = "High Score: %d" % new_high
	_update_leaderboard()

func _update_leaderboard():
	# show top 5 from Global.scores if available
	for child in leaderboard.get_children():
		child.queue_free()
	if Global.scores.size() == 0:
		var l = Label.new()
		l.text = "No scores yet"
		leaderboard.add_child(l)
		return
	var top = Global.scores.duplicate()
	# assume each entry is a Dictionary {playerName, score, timestamp}
	top.sort_custom(self, "_sort_scores")
	for i in range(min(5, top.size())):
		var d = top[i]
		var lbl = Label.new()
		lbl.text = "%d. %s - %d" % [i+1, str(d.get("playerName", "Anon")), int(d.get("score",0))]
		leaderboard.add_child(lbl)

func _sort_scores(a, b):
	return int(b.get("score",0)) - int(a.get("score",0))