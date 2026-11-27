extends State

# Standing back up from prone. Can't be cancelled (the cost of going prone).

const RECOVERY_DURATION: float = 0.6
var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.velocity.x = 0
	player.sprite.play("pushup")

func physics_update(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	player.velocity.x = 0
	if timer >= RECOVERY_DURATION:
		transitioned.emit("idle")
		return
	player.move_and_slide()
