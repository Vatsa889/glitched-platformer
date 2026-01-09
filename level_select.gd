extends Control

func _on_level_1_btn_pressed():
	get_tree().change_scene_to_file("res://level_1.tscn")

func _on_level_2_btn_pressed():
	# Placeholder for when level 2 is finished
	print("Level 2 is not done yet")

func _on_back_btn_pressed():
	# Return to the main menu
	get_tree().change_scene_to_file("res://start_menu.tscn")
