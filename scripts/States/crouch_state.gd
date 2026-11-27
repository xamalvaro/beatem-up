extends State

func enter() -> void:
	player.sprite.play("crouch")
	player.velocity.x = 0

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var buf: InputBuffer = player.input_buffer

	if not Input.is_action_pressed("ui_down"):
		transitioned.emit("idle")
		return
	if player.wants_dodge():
		transitioned.emit("dodge")
		return
	if buf.consume(&"attack_a"):
		transitioned.emit("sweep")
		return
	if buf.consume(&"crawl"):
		transitioned.emit("crawlenter")
		return
	if player.get_move_input() != 0:
		transitioned.emit("crouchwalk")
		return

	player.velocity.x = 0
	player.move_and_slide()
