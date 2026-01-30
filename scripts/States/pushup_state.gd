extends State

var recovery_time: float = 0.0
var recovery_duration: float = 0.5

func enter() -> void:
	player.get_node("AnimatedSprite2D").play("pushup")
	recovery_time = 0.0
	player.velocity.x = 0

func physics_update(delta: float) -> void:
	recovery_time += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# After recovery animation, go to crouch
	if recovery_time >= recovery_duration:
		transitioned.emit("crouch")
	
	player.velocity.x = 0
	player.move_and_slide()
