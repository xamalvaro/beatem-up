extends State

# Short flinch when hit: knocked back, can't act. Interrupts attacks.
# Inputs pressed during the flinch stay buffered for when it ends.

const DURATION: float = 0.25
var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.velocity = player.hurt_knockback
	player.sprite.play("idle")  # Placeholder — swap for a hurt animation

func physics_update(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0, 400.0 * delta)
	player.move_and_slide()
	if timer >= DURATION and player.is_on_floor():
		transitioned.emit("idle")
