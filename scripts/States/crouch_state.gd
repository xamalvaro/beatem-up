extends State

var crouch_time: float = 0.0

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("crouch")
	crouch_time = 0.0
	player.velocity.x = 0

func physics_update(delta: float) -> void:
	crouch_time += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_down = Input.is_action_pressed("ui_down")
	
	# Transitions from crouch
	if not is_down:
		# Stand up
		transitioned.emit("idle")
	elif direction != 0:
		# Move while crouched
		transitioned.emit("crouch_walk")
	elif Input.is_action_just_pressed("attack_a"):
		# Sweep from crouch
		transitioned.emit("sweep")
	elif Input.is_action_just_pressed("attack_b"):
		# Go into crawl
		transitioned.emit("crawl")
	
	player.velocity.x = 0
	player.move_and_slide()
