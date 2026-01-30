extends State

var has_attacked: bool = false

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("crouch")
	player.velocity.x = 0
	has_attacked = false
	print(">>> Entered CROUCH state")

func exit() -> void:
	print(">>> Exited CROUCH state")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_down = Input.is_action_pressed("ui_down")
	
	# Transitions from crouch
	if not is_down:
		print(">>> Crouch: Standing up")
		transitioned.emit("idle")
		return
	
	if direction != 0:
		print(">>> Crouch: Starting crouch walk")
		transitioned.emit("crouchwalk")
		return
	
	if Input.is_action_just_pressed("attack_a") and not has_attacked:
		has_attacked = true
		print(">>> Crouch: Starting sweep attack")
		transitioned.emit("sweep")
		return
	
	if Input.is_action_just_pressed("crawl"):
		print(">>> Crouch: Going into prone")
		transitioned.emit("crawlenter")  # Changed to crawlenter
		return
	
	player.velocity.x = 0
	player.move_and_slide()
