extends CharacterBody2D

const SPEED = 100.0
var direction = 1 # 1 is Right, -1 is Left

@onready var sprite = $Sprite2D

func _physics_process(delta):
	# applies Gravity
	if not is_on_floor():
		velocity.y += 980.0 * delta

	# check for walls or ledges to flip direction
	if is_on_wall():
		direction *= -1
		
		# sprite flipping
	if direction > 0:
		sprite.flip_h = true # Face left (Default)
	elif direction < 0:
		sprite.flip_h = false  # face right (Flip it)
		
	# move
	velocity.x = direction * SPEED
	move_and_slide()

## this function will run when the Player touches the Hitbox
func _on_hitbox_body_entered(body):
	if body.name == "Player":
		print("antivirus killed me in cold blood")
		call_deferred("reload_level")

func reload_level():
	get_tree().reload_current_scene()
