extends State

func enter() -> void:
	player.sprite.play("run")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	if try_neutral_actions():
		return
	var direction = player.get_move_input()
	if direction == 0:
		transitioned.emit("idle")
		return

	player.velocity.x = direction * player.SPEED * player.speed_multiplier
	player.face(direction)
	player.move_and_slide()
