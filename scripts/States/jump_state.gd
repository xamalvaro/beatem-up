extends State

func enter() -> void:
	player.velocity.y = player.JUMP_VELOCITY
	player.get_node("AnimatedSprite2D").play("jumping")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	else:
		# Land
		transitioned.emit("idle")
	
	# Allow air control
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		player.velocity.x = direction * player.SPEED
		player.get_node("AnimatedSprite2D").flip_h = direction < 0
	
	player.move_and_slide()
