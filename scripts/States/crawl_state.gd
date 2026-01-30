extends State

const CRAWL_SPEED = 40.0
var crawl_time: float = 0.0
var max_crawl_time: float = 2.0  # Auto-recovery after 2 seconds

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("crawl")
	crawl_time = 0.0

func physics_update(delta: float) -> void:
	crawl_time += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Auto-recovery after max time
	if crawl_time >= max_crawl_time:
		transitioned.emit("pushup")
		return
	
	# Manual recovery
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack_a"):
		transitioned.emit("pushup")
		return
	
	# Sweep from crawl
	if Input.is_action_just_pressed("attack_b"):
		transitioned.emit("sweep")
		return
	
	# Move while crawling
	if direction != 0:
		player.velocity.x = direction * CRAWL_SPEED
		player.get_node("AnimatedSprite2D").flip_h = direction < 0
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, CRAWL_SPEED)
	
	player.move_and_slide()
