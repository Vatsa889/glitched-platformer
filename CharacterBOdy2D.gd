extends CharacterBody2D

## player settings
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const GRAVITY = 1200.0

# player nodes
@onready var sprite = $Sprite2D

func _physics_process(delta):
	# apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# jumping mechanics
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		perform_squash_stretch(0.6, 1.4) # character streches thin when jumping
		
	# glitch mechanic (phase jump)
	# when holding the button, the players stops colliding with Layer 3 (GlitchObject)
	if Input.is_action_pressed("glitch"):
		set_collision_mask_value(3, false) # turns off collision with Layer 3
		sprite.modulate.a = 0.5 # visual cue: semi transparent
	else:
		set_collision_mask_value(3, true) # Turns on collision with Layer 3
		sprite.modulate.a = 1.0 # visual cue: solid

	## movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	## landing detection for squash effect
	## checks if we were in air last frame but on floor this frame
	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		perform_squash_stretch(1.3, 0.7) # Squash flat when landing

## polishing squash and stretch
func perform_squash_stretch(x_scale, y_scale):
	# Create a new Tween (animation)
	var tween = create_tween()
	# Instantly set sprite to the squash/stretch shape
	tween.tween_property(sprite, "scale", Vector2(x_scale, y_scale), 0.05)
	# Smoothly return to normal (1, 1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
