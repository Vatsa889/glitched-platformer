extends CharacterBody2D

## player settings
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const GRAVITY = 1200.0

## glitch settings
var glitch_battery = 100.0       # starts at 100% charge
const DRAIN_RATE = 40.0          # drains in 2.5 seconds (100 / 40)
const RECHARGE_FAST = 20.0       # normal recharge speed 
const RECHARGE_SLOW = 8.0        # punishment speed if battery is < 10%
var is_overheated = false        # if true, you are locked out of the ability
var is_in_penalty = false        # tracks if we need to recharge slowly

## player nodes
@onready var sprite = $Sprite2D
@onready var battery_bar = $CanvasLayer/ProgressBar

func _physics_process(delta):
	# apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# jumping mechanics
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		perform_squash_stretch(0.6, 1.4) # character streches thin when jumping
		
	## glitch mechanic with the new battery
	## we check if button is held AND if we are allowed to use it (not overheated)
	if Input.is_action_pressed("glitch") and not is_overheated:
		# ACTIVE MODE
		set_collision_mask_value(3, false) # turns off collision with Layer 3
		sprite.modulate.a = 0.5            # visual cue: semi transparent
		
		# drain the battery
		glitch_battery -= DRAIN_RATE * delta
		
		# check if we used too much (dropped below 10%)
		if glitch_battery < 10.0:
			is_in_penalty = true # activate slow recharge mode
		
		# check if we ran out
		if glitch_battery <= 0:
			glitch_battery = 0
			is_overheated = true # LOCK THE ABILITY!
			
	else:
		# recharge mode
		set_collision_mask_value(3, true) # turns on collision with Layer 3
		sprite.modulate.a = 1.0           # visual cue: solid
		
		# variable recharge logic
		# if we are in penalty mode, use slow speed. otherwise fast.
		if is_in_penalty:
			glitch_battery += RECHARGE_SLOW * delta
		else:
			glitch_battery += RECHARGE_FAST * delta
			
		# cap at 100
		if glitch_battery >= 100:
			glitch_battery = 100
			is_in_penalty = false # penalty is over, we are full again!
			
		# if we were overheated, wait until full to unlock
		if is_overheated and glitch_battery >= 100:
			is_overheated = false # UNLOCK THE ABILITY!

	## update ui bar
	if battery_bar:
		battery_bar.value = glitch_battery

	## movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	## landing detection for squash effect
	## checks if it was in air last frame but on floor this frame
	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		perform_squash_stretch(1.3, 0.7) # squash flat when landing

## polishing squash and stretch
func perform_squash_stretch(x_scale, y_scale):
	# create a new Tween (animation)
	var tween = create_tween()
	# instantly set sprite to the squash/stretch shape
	tween.tween_property(sprite, "scale", Vector2(x_scale, y_scale), 0.05)
	# smoothly return to normal (1, 1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
