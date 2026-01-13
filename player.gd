extends CharacterBody2D

## glitch stuff
signal glitch_toggled(is_active)
var is_glitching_active = false
var original_scale = Vector2(1, 1)

## hoverboard settings
const MAX_SPEED = 500.0        # Top speed
const ACCELERATION = 900.0     # How fast you speed up (lower = more "drift")
const FRICTION = 600.0         # How fast you slow down when letting go
const JUMP_VELOCITY = -500.0
const GRAVITY = 1200.0

## weight mechanic (pressing the s key)
const HEAVY_GRAVITY_MULT = 3.0 # gravity becomes 3x stronger while pressing the s key
const MAX_FALL_SPEED = 1500.0

## glitch settings
var glitch_battery = 100.0       
const DRAIN_RATE = 40.0          
const RECHARGE_FAST = 20.0       
const RECHARGE_SLOW = 8.0        
var is_overheated = false        
var is_in_penalty = false        

## player nodes
@onready var sprite = $Sprite2D
@onready var battery_bar = $CanvasLayer/ProgressBar
@onready var particles = $Sprite2D/GlitchParticles 
@onready var anim = $AnimationPlayer

func _ready():
	add_to_group("player")
	original_scale = sprite.scale

func _physics_process(delta):
	## 1. HOVERBOARD MOVEMENT (Momentum)
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		# slowly speed up towards max speed
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
		
		# simple visual tilt (lean forward)
		sprite.rotation = lerp_angle(sprite.rotation, direction * 0.1, 10 * delta)
	else:
		# drift to a stop
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
		# tilt back to 0 (upright)
		sprite.rotation = lerp_angle(sprite.rotation, 0, 10 * delta)

	## 2. GRAVITY & WEIGHT MECHANIC
	if not is_on_floor():
		var current_gravity = GRAVITY
		
		# if holding 'S' (or Down Arrow), increase gravity
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			current_gravity *= HEAVY_GRAVITY_MULT
			
		velocity.y += current_gravity * delta
		
		# cap fall speed so we don't glitch through floors
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# jumping section
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			perform_squash_stretch(0.6, 1.4)
			
		elif is_on_wall() and is_touching_safe_wall():
			velocity.y = JUMP_VELOCITY 
			velocity.x = get_wall_normal().x * MAX_SPEED # kick off wall at full speed
			perform_squash_stretch(0.7, 1.3)

	## glitch mechanic (same as before)
	var trying_to_glitch = Input.is_action_pressed("glitch") and not is_overheated
	
	if trying_to_glitch != is_glitching_active:
		is_glitching_active = trying_to_glitch
		glitch_toggled.emit(is_glitching_active) 
		
		if is_glitching_active:
			set_collision_mask_value(3, false)
			sprite.modulate.a = 0.5
		else:
			set_collision_mask_value(3, true)
			sprite.modulate.a = 1.0
			particles.emitting = false

	if is_glitching_active:
		if velocity.length() > 10.0:
			particles.emitting = true
		else:
			particles.emitting = false
		
		glitch_battery -= DRAIN_RATE * delta
		if glitch_battery < 10.0: is_in_penalty = true
		if glitch_battery <= 0:
			glitch_battery = 0
			is_overheated = true
	else:
		if is_in_penalty: glitch_battery += RECHARGE_SLOW * delta
		else: glitch_battery += RECHARGE_FAST * delta
			
		if glitch_battery >= 100:
			glitch_battery = 100
			is_in_penalty = false
		if is_overheated and glitch_battery >= 100: is_overheated = false

	# physics application
	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		perform_squash_stretch(1.3, 0.7)

## animation logic
	
	# flip the sprite based on movement direction
	if velocity.x < 0:
		sprite.flip_h = true  # face left
	elif velocity.x > 0:
		sprite.flip_h = false # face right
	
	# decide which animation to play
	if is_on_floor():
		if abs(velocity.x) > 10: # If we are moving noticeably
			anim.play("run")
		else:
			anim.play("idle")
	else:

		if velocity.y < 0:
			if anim.has_animation("jump"): anim.play("jump")
			else: anim.play("run") 
		else:
			if anim.has_animation("fall"): anim.play("fall")
			else: anim.play("run")
			
	# battery UI
	if battery_bar:
		battery_bar.value = glitch_battery
		var stylebox = battery_bar.get_theme_stylebox("fill")
		if is_overheated: stylebox.bg_color = Color.RED
		elif glitch_battery < 10.0: stylebox.bg_color = Color.YELLOW
		else: stylebox.bg_color = Color(0.0, 0.73, 0.17)

func is_touching_safe_wall() -> bool:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.has_method("get_collision_layer_value"):
			if collider.get_collision_layer_value(2): return true
		elif collider is TileMapLayer or collider is TileMap:
			return true
	return false

func perform_squash_stretch(x_mult, y_mult):
	var tween = create_tween()
	# calculate the squashed size based on the ORIGINAL size
	var target_size = Vector2(original_scale.x * x_mult, original_scale.y * y_mult)
	# switch to the squashed size
	tween.tween_property(sprite, "scale", target_size, 0.05)
	# switch back to the ORIGINAL size (instead of just "1.0")
	tween.tween_property(sprite, "scale", original_scale, 0.15)
