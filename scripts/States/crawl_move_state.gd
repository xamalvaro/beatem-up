extends State

const CRAWL_SPEED = 40.0

func enter() -> void:
	player.sprite.play("crawl_move")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var buf: InputBuffer = player.input_buffer
	var direction := player.get_move_input()

	if buf.consume(&"crawl"):
		transitioned.emit("pushup")
		return
	if buf.consume(&"attack_a"):
		transitioned.emit("crawlsweep")
		return
	if direction == 0:
		transitioned.emit("crawlidle")
		return

	player.velocity.x = direction * CRAWL_SPEED
	player.face(direction)
	player.move_and_slide()
