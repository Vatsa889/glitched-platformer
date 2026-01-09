extends CharacterBody2D

## glitch stuff
signal glitch_toggled(is_active)
var is_glitching_active = false

## player settings
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const GRAVITY = 1200.0
const WALL_SLIDE_SPEED = 200.0 # max fall speed when hugging a wall

## glitch settings
var glitch_battery = 100.0       # starts at 100% charge
const DRAIN_RATE = 40.0          # drains in 2.5 seconds
const RECHARGE_FAST = 20.0       # normal recharge speed 
const RECHARGE_SLOW = 8.0        # punishment speed if battery is < 10%
var is_overheated = false        # lock out ability
var is_in_penalty = false        # slow recharge mode

## player nodes
@onready var sprite = $Sprite2D
@onready var battery_bar = $CanvasLayer/ProgressBar
@onready var particles = $GlitchParticles

func _ready():
	# adding player to group so gates can find me
	add_to_group("player")

func _physics_process(delta):
	## movement input
	# calculated so wall jumps can override it later
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# gravity and wall slid stuff
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
		# fall slower while hugging wall
		if is_on_wall() and velocity.y > 0 and is_touching_safe_wall():
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

	# jumping section
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# normal floor jump
			velocity.y = JUMP_VELOCITY
			perform_squash_stretch(0.6, 1.4)
			
		elif is_on_wall() and is_touching_safe_wall():
			# wall jump
			velocity.y = JUMP_VELOCITY # jump up
			# kick away from the wall 
			velocity.x = get_wall_normal().x * SPEED 
			perform_squash_stretch(0.7, 1.3)

	## glitch mechanic
	var trying_to_glitch = Input.is_action_pressed("glitch") and not is_overheated
	
	# check if we just pressed or released the button
	if trying_to_glitch != is_glitching_active:
		is_glitching_active = trying_to_glitch
		glitch_toggled.emit(is_glitching_active) # tells the gate to open/close
		
		# toggle visuals and collision
		if is_glitching_active:
			set_collision_mask_value(3, false)
			sprite.modulate.a = 0.5
		else:
			set_collision_mask_value(3, true)
			sprite.modulate.a = 1.0
			particles.emitting = false

	# handle the continuous drain or recharge
	if is_glitching_active:
		# particle logic
		if velocity.length() > 10.0:
			particles.emitting = true
		else:
			particles.emitting = false
		
		# drains battery while active
		glitch_battery -= DRAIN_RATE * delta
		
		if glitch_battery < 10.0:
			is_in_penalty = true
		
		if glitch_battery <= 0:
			glitch_battery = 0
			is_overheated = true # this forces trying_to_glitch to false next frame
			
	else:
		# recharge mode
		if is_in_penalty:
			glitch_battery += RECHARGE_SLOW * delta
		else:
			glitch_battery += RECHARGE_FAST * delta
			
		if glitch_battery >= 100:
			glitch_battery = 100
			is_in_penalty = false
			
		if is_overheated and glitch_battery >= 100:
			is_overheated = false

	# physics application
	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		perform_squash_stretch(1.3, 0.7)

	# update the battery when it's about to be depleted
	if battery_bar:
		battery_bar.value = glitch_battery
		
		var stylebox = battery_bar.get_theme_stylebox("fill")
		
		if is_overheated:
			# red: unusable/recharging from 0
			stylebox.bg_color = Color.RED
		elif glitch_battery < 10.0:
			# yellow: low battery
			stylebox.bg_color = Color.YELLOW
		else:
			# green: normal
			stylebox.bg_color = Color(0.0, 0.73, 0.17)

## helper function
# checks if the wall we are touching is on layer 2 (world)
func is_touching_safe_wall() -> bool:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		# if the collider is on layer 2, it will be seen as safe
		if collision.get_collider().get_collision_layer_value(2):
			return true
	return false

## polishing squash and stretch
func perform_squash_stretch(x_scale, y_scale):
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(x_scale, y_scale), 0.05)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
