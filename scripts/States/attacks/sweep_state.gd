extends State

var attack_timer: float = 0.0
var attack_duration: float = 0.5  # Adjust based on your animation length
var attack_finished: bool = false
var combo_timer: float = 0.0
var combo_window: float = 0.4

func enter() -> void:
	attack_timer = 0.0
	attack_finished = false
	combo_timer = 0.0
	player.velocity.x = 0
	player.get_node("AnimatedSprite2D").play("sweep")
	print(">>> Entered SWEEP state")

func exit() -> void:
	print(">>> Exited SWEEP state")

func physics_update(delta: float) -> void:
	attack_timer += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# Keep player stationary
	player.velocity.x = 0
	
	# Wait for attack to finish
	if not attack_finished and attack_timer >= attack_duration:
		attack_finished = true
		print(">>> SWEEP attack finished - combo window open")
	
	# After attack finishes, check for combo or return to idle
	if attack_finished:
		combo_timer += delta
		
		if combo_timer < combo_window:
			# Check for combo into stomp
			if Input.is_action_just_pressed("attack_a"):
				print(">>> SWEEP: Combo into stomp")
				transitioned.emit("stomp")
				return
		else:
			# Combo window expired, return to idle
			print(">>> SWEEP: Combo window expired, returning to idle")
			transitioned.emit("idle")
			return
	
	player.move_and_slide()
