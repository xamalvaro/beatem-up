extends State

func enter() -> void:
	player.sprite.play("crawl")
	player.velocity.x = 0

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var buf: InputBuffer = player.input_buffer

	if buf.consume(&"crawl"):
		transitioned.emit("pushup")  # Press C again to stand
		return
	if buf.consume(&"attack_a"):
		transitioned.emit("crawlsweep")
		return
	if player.get_move_input() != 0:
		transitioned.emit("crawlmove")
		return

	player.velocity.x = 0
	player.move_and_slide()
