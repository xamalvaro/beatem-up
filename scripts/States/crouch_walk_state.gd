extends State

const CROUCH_SPEED = 50.0

func enter() -> void:
	player.sprite.play("crouch_walk")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var buf: InputBuffer = player.input_buffer
	var direction := player.get_move_input()

	if not Input.is_action_pressed("ui_down"):
		transitioned.emit("run" if direction != 0 else "idle")
		return
	if buf.consume(&"attack_a"):
		transitioned.emit("sweep")
		return
	if buf.consume(&"crawl"):
		transitioned.emit("crawlenter")
		return
	if direction == 0:
		transitioned.emit("crouch")
		return

	player.velocity.x = direction * CROUCH_SPEED
	player.face(direction)
	player.move_and_slide()
