extends Area2D

func _on_body_entered(body):
	# checks if the "thing" that entered is the player
	if body.name == "Player":
		print("Player died, restarting level")
		# reloads the current level from the start
		call_deferred("reload_level")

func reload_level():
	get_tree().reload_current_scene()
