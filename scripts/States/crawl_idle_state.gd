extends State

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("crawl")
	player.velocity.x = 0
	print(">>> Entered CRAWL IDLE state (prone position)")

func exit() -> void:
	print(">>> Exited CRAWL IDLE state")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Transitions from crawl idle
	if Input.is_action_just_pressed("crawl"):
		# Press C again to start recovery
		print(">>> CRAWL IDLE: Starting recovery (pushup)")
		transitioned.emit("pushup")
		return
	
	if Input.is_action_just_pressed("attack_a"):
		# Attack from crawl - forces recovery after
		print(">>> CRAWL IDLE: Attacking (sweep with recovery)")
		transitioned.emit("crawlsweep")
		return
	
	if direction != 0:
		# Start crawling movement
		print(">>> CRAWL IDLE: Starting crawl movement")
		transitioned.emit("crawlmove")
		return
	
	# Stay stationary
	player.velocity.x = 0
	player.move_and_slide()
