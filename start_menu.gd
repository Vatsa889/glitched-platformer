extends Control

func _on_start_game_pressed():
	# loads the actual game level
	# make sure to update path in the future
	get_tree().change_scene_to_file("res://level_1.tscn")

func _on_quit_pressed():
	# closes the game window
	get_tree().quit()
