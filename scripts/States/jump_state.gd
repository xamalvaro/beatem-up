extends State

# Handles both jumping and falling (walking off a ledge).
# player.jump_requested is set by the state that sends us here.

var jump_cut_done: bool = false

func enter() -> void:
	if player.jump_requested:
		player.start_jump()
		jump_cut_done = false
	else:
		jump_cut_done = true  # Falling — nothing to cut
	player.jump_requested = false
	player.sprite.play("jumping")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	# Coyote jump: just walked off a ledge and pressed jump
	if player.velocity.y >= 0 and player.wants_jump():
		player.start_jump()
		jump_cut_done = false

	# Variable jump height — releasing jump early cuts the rise short
	if not jump_cut_done and player.velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
		player.velocity.y *= player.JUMP_CUT
		jump_cut_done = true

	# Aerial attack
	if player.input_buffer.consume(&"attack_a"):
		transitioned.emit("dropkick")
		return

	# Air control
	var direction = player.get_move_input()
	if direction != 0:
		player.velocity.x = direction * player.SPEED * player.speed_multiplier
		player.face(direction)

	player.move_and_slide()

	# Land check AFTER moving, so the first frame of a jump (still touching
	# the floor from last frame) doesn't count as landing.
	if player.is_on_floor() and player.velocity.y >= 0:
		transitioned.emit("run" if direction != 0 else "idle")
