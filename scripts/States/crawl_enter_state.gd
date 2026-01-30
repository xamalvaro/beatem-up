extends State

var enter_duration: float = 0.4  # Time to get into prone position
var enter_timer: float = 0.0

func enter() -> void:
	enter_timer = 0.0
	player.velocity.x = 0
	# You might have a specific "going prone" animation
	# For now, we'll use crawl animation
	player.get_node("AnimatedSprite2D").play("going_prone")
	print(">>> Entered CRAWL ENTER state (getting prone)")

func exit() -> void:
	print(">>> Exited CRAWL ENTER state")

func physics_update(delta: float) -> void:
	enter_timer += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# Force stationary during transition
	player.velocity.x = 0
	
	# After transition completes, go to idle crawl state
	if enter_timer >= enter_duration:
		print(">>> CRAWL ENTER complete, transitioning to crawl idle")
		transitioned.emit("crawlidle")
	
	player.move_and_slide()
