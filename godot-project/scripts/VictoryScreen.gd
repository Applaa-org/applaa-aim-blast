extends Control

@onready var final_label := $Panel/VBox/FinalScore
@onready var high_label := $Panel/VBox/HighScore
@onready var restart_btn := $Panel/VBox/RestartButton
@onready var menu_btn := $Panel/VBox/MainMenuButton
@onready var close_btn := $Panel/VBox/CloseButton

func _ready():
	# Show final score and high score
	final_label.text = "Your Score: %d" % Global.score
	high_label.text = "High Score: %d" % Global.high_score
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	close_btn.pressed.connect(_on_close)
	# Ensure high score label visible
	high_label.visible = true

func _on_restart():
	Global.reset_score()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu():
	Global.reset_score()
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _on_close():
	# Save final score with player name
	var name = Global.player_name if Global.player_name != "" else "Player"
	Global.save_score_to_storage(name, Global.score)
	get_tree().quit()