extends State

# Getting down into prone. Committed until finished.

const ENTER_DURATION: float = 0.4
var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.velocity.x = 0
	player.sprite.play("going_prone")

func physics_update(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	player.velocity.x = 0
	if timer >= ENTER_DURATION:
		transitioned.emit("crawlidle")
		return
	player.move_and_slide()
