extends State

# Quick dash with invincibility frames. Goes in the held direction,
# or backwards (away from where you face) if no direction is held.

const DURATION: float = 0.25
const SPEED_MULT: float = 2.4
const COOLDOWN: float = 0.35

var timer: float = 0.0
var dir: float = 1.0

func enter() -> void:
	timer = 0.0
	var input := player.get_move_input()
	dir = signf(input) if input != 0 else -player.facing()
	player.is_dodging = true
	player.is_invincible = true
	player.modulate = Color(1, 1, 1, 0.5)
	player.sprite.play("run")  # Placeholder — swap for a roll animation
	player.sprite.speed_scale = 2.0

func exit() -> void:
	player.is_dodging = false
	player.is_invincible = false
	player.modulate = Color(1, 1, 1)
	player.sprite.speed_scale = 1.0
	player.dodge_cooldown = COOLDOWN

func physics_update(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	player.velocity.x = dir * player.SPEED * SPEED_MULT
	player.move_and_slide()
	if timer >= DURATION:
		transitioned.emit("run" if player.get_move_input() != 0 else "idle")
