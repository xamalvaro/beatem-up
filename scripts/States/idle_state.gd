extends State

func enter() -> void:
	player.sprite.play("idle")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	if try_neutral_actions():
		return
	if player.get_move_input() != 0:
		transitioned.emit("run")
		return

	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	player.move_and_slide()
