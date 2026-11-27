extends State

const CROUCH_SPEED = 50.0

func enter() -> void:
	player.sprite.play("crouch_walk")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_down = Input.is_action_pressed("ui_down")
	
	# Transitions
	if not is_down:
		# Stand up
		transitioned.emit("idle")
		return
	
	if direction == 0:
		# Stop moving
		transitioned.emit("crouch")
		return
	
	if player.input_buffer.consume(&"attack_a"):
		transitioned.emit("sweep")
		return
	
	if player.input_buffer.consume(&"crawl"):
		transitioned.emit("crawlenter")  # Changed to crawlenter
		return
	
	# Move slowly while crouched
	if direction != 0:
		player.velocity.x = direction * CROUCH_SPEED
		player.sprite.flip_h = direction < 0
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, CROUCH_SPEED)
	
	player.move_and_slide()
