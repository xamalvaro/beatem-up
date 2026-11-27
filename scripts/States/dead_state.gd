extends State

# Player is out. Lie still, then restart the level.

const RESTART_DELAY: float = 2.5
var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.velocity.x = 0
	player.is_invincible = true
	player.modulate = Color(0.5, 0.5, 0.5)
	player.sprite.play("crawl")  # Placeholder — swap for a death animation
	player.input_buffer.clear()

func physics_update(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	player.velocity.x = 0
	player.move_and_slide()
	if timer >= RESTART_DELAY:
		player.get_tree().reload_current_scene()
