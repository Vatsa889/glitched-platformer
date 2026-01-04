extends Area2D

func _process(delta):
	# make it spin
	rotation += 2.0 * delta

func _on_body_entered(body):
	if body.name == "Player":
		# give Battery
		body.glitch_battery += 30.0
		
		# safety Cap: Don't let it go over 100
		if body.glitch_battery > 100.0:
			body.glitch_battery = 100.0
			
		if body.glitch_battery > 10.0:
			body.is_in_penalty = false
		
		# Remove the shard
		queue_free()
