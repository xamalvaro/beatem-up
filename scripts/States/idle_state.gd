extends State

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("idle")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# Check for transitions
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_down = Input.is_action_pressed("ui_down")
	
	if direction != 0:
		transitioned.emit("run")
	elif Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		transitioned.emit("jump")
	# Directional attacks from idle
	elif is_down and Input.is_action_just_pressed("attack_a"):
		transitioned.emit("sweep")
	elif is_down:
		transitioned.emit("crouch")
	elif Input.is_action_just_pressed("attack_a"):
		transitioned.emit("stomp")  # Changed from attack_a
	elif Input.is_action_just_pressed("attack_b"):
		transitioned.emit("crawl")  # B goes into crawl
	
	# Apply movement
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	player.move_and_slide()
