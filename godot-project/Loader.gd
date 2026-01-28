extends Node

func _ready():
	# Start with StartScreen
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")