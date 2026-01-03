extends Area2D

func _process(delta):
	# makes it spin so it looks like it wants to be collected
	rotation += 2.0 * delta

func _on_body_entered(body):
	if body.name == "Player":
		# access the player's battery variable directly
		body.glitch_battery += 30.0
		
		# TODO optional: play a sound here later
		
		# remove the coin from the world
		queue_free()
