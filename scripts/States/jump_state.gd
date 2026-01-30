extends State

func enter() -> void:
	player.velocity.y = player.JUMP_VELOCITY
	player.get_node("AnimatedSprite2D").play("jumping")
	print(">>> Entered JUMP state")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	else:
		# Land
		print(">>> Landed - transitioning to idle")
		transitioned.emit("idle")
	
	# Aerial attack - emit "dropkick" (lowercase)
	if Input.is_action_just_pressed("attack_a"):
		print(">>> Attempting transition to dropkick")
		transitioned.emit("dropkick")  # Changed to lowercase
	
	# Allow air control
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		player.velocity.x = direction * player.SPEED
		player.get_node("AnimatedSprite2D").flip_h = direction < 0
	
	player.move_and_slide()
