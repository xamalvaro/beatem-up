extends State

var has_landed: bool = false
var land_timer: float = 0.0
var land_recovery_time: float = 0.3  # Time to recover after landing

func enter() -> void:
	has_landed = false
	land_timer = 0.0
	player.get_node("AnimatedSprite2D").play("drop_kick")
	
	# Strong downward boost
	#player.velocity.y = 100
	
	print(">>> Entered DROP KICK state")

func exit() -> void:
	print(">>> Exited DROP KICK state")

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta * 1.5
	else:
		# Handle landing
		if not has_landed:
			has_landed = true
			player.velocity.x = 0  # Stop horizontal movement on landing
			print(">>> DROP KICK landed - recovery phase")
		
		# Count recovery time after landing
		land_timer += delta
		if land_timer >= land_recovery_time:
			print(">>> DROP KICK recovery complete, returning to idle")
			transitioned.emit("idle")
			return
	
	# Air control during descent
	if not has_landed:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.4
			player.get_node("AnimatedSprite2D").flip_h = direction < 0
	
	player.move_and_slide()
