extends State

const CRAWL_SPEED = 40.0

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("crawl_move")  # Use crawl animation (or create crawl_move if you have it)
	print(">>> Entered CRAWL MOVE state")

func exit() -> void:
	print(">>> Exited CRAWL MOVE state")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Transitions from crawl move
	if Input.is_action_just_pressed("crawl"):
		# Start recovery
		print(">>> CRAWL MOVE: Starting recovery (pushup)")
		transitioned.emit("pushup")
		return
	
	if Input.is_action_just_pressed("attack_a"):
		# Attack from crawl
		print(">>> CRAWL MOVE: Attacking (sweep with recovery)")
		transitioned.emit("crawlsweep")
		return
	
	if direction == 0:
		# Stop moving
		print(">>> CRAWL MOVE: Stopped moving")
		transitioned.emit("crawlidle")
		return
	
	# Move while crawling
	if direction != 0:
		player.velocity.x = direction * CRAWL_SPEED
		player.get_node("AnimatedSprite2D").flip_h = direction < 0
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, CRAWL_SPEED)
	
	player.move_and_slide()
