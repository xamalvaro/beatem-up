extends State

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("run")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# Get input
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_down = Input.is_action_pressed("ui_down")
	
	# Check for transitions
	if direction == 0:
		transitioned.emit("idle")
	elif Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		transitioned.emit("jump")
	elif is_down and Input.is_action_just_pressed("attack_a"):
		transitioned.emit("sweep")
	elif is_down:
		transitioned.emit("crouch")
	elif Input.is_action_just_pressed("attack_a"):
		transitioned.emit("stomp")
	elif Input.is_action_just_pressed("crawl"):
		transitioned.emit("crawlenter")  # Changed to crawlenter
	
	# Apply movement
	if direction != 0:
		player.velocity.x = direction * player.SPEED
		player.get_node("AnimatedSprite2D").flip_h = direction < 0
	
	player.move_and_slide()
