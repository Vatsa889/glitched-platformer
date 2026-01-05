extends StaticBody2D

@onready var anim = $AnimationPlayer

func _ready():
	# find the player and listen for the signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.glitch_toggled.connect(_on_player_glitch)
	
	anim.play("close") # starts closed

func _on_player_glitch(is_active: bool):
	if is_active:
		anim.play("open")
	else:
		anim.play("close")
