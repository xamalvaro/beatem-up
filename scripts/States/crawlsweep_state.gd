extends State

var attack_timer: float = 0.0
var attack_duration: float = 0.5
var attack_finished: bool = false
var combo_timer: float = 0.0
var combo_window: float = 0.3

func enter() -> void:
	attack_timer = 0.0
	attack_finished = false
	combo_timer = 0.0
	player.velocity.x = 0
	player.get_node("AnimatedSprite2D").play("sweep")
	print(">>> Entered CRAWL SWEEP state (attack from prone)")

func exit() -> void:
	print(">>> Exited CRAWL SWEEP state")

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
		print(">>> CRAWL SWEEP finished - forcing recovery")
	
	# After attack finishes, must do recovery (punishment)
	if attack_finished:
		combo_timer += delta
		
		if combo_timer >= combo_window:
			# Force recovery after sweep from crawl
			print(">>> CRAWL SWEEP: Forcing pushup recovery")
			transitioned.emit("pushup")
			return
	
	player.move_and_slide()
