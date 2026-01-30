extends State

var recovery_time: float = 0.0
var recovery_duration: float = 0.6  # Made slightly longer

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("pushup")
	recovery_time = 0.0
	player.velocity.x = 0

func physics_update(delta: float) -> void:
	recovery_time += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# Cannot cancel recovery - must finish
	# After recovery animation, go to idle (stand up)
	if recovery_time >= recovery_duration:
		transitioned.emit("idle")  # Stand up after recovery
	
	player.velocity.x = 0
	player.move_and_slide()
