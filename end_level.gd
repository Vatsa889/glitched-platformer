extends Area2D

func _on_body_entered(body):
	# check if the player entered the zone
	if body.name == "Player":
		print("level complete!")
		
		# 
		# no level 2 rn so once done set it to "res://level_2.tscn"
		get_tree().change_scene_to_file("res://level_select.tscn")
